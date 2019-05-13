DESIGN_NAME := manycore
BUCKET_NAME := bsgamibuild
CORNELL_USER_ID := 238771226843
UW_USER_ID := 339237448643

# Default to the standard origin name
ORIGIN_NAME := origin
# Parse the branch name from the repository root. This is done automatically to
# resolve a circular dependency when building
BRANCH_NAME:=$(shell git symbolic-ref --short HEAD)
# If the current branch is not master, then this is a Release Candidate (RC) build
ifneq ('$(BRANCH_NAME)','master')
RC_STR=rc
endif

# ISDIRTY_CHECK is set to dirty_repo (a target) if the repository has unpushed, or uncommited changes.
# This is a failsafe against building an AMI/AGFI with changes that are not globally visible
ISDIRTY_CHECK:= $(shell git diff-index --quiet $(ORIGIN_NAME)/$(BRANCH_NAME) -- || echo dirty_check)

include Makefile.common

.PHONY: all build-dcp upload-agfi build-ami clean help share-ami share-afi

.DEFAULT_GOAL := help
all: help
help:
	@echo "Usage:"
	@echo "make {build-ami|build-dcp|upload-agfi|clean} "
	@echo "		build-ami: Build an Amazon Machine Image (AMI) using "
	@echo "		           the AGFI and AFI in Makefile.deps "
	@echo "		build-dcp: Compile the FPGA design (locally) with the "
	@echo "		           hashes and repositories in Makefile.deps "
	@echo "		upload-agfi: Upload the compiled FPGA design into S3 "
	@echo "		           and create an Amazon FPGA Image (AFI) "
	@echo "		           and an Amazon Global FPGA Image ID (AGFI)"
	@echo "		clean: Remove all build files and repositories"

dirty_check:
	@echo "Error! bsg_bladerunner repository is dirty. Push commits before building"
	@exit 1

build-ami: $(ISDIRTY_CHECK) checkout-repos
	$(BSG_F1_DIR)/scripts/amibuild/build.py Bladerunner bsg_bladerunner@$(BRANCH_NAME) $(AFI_ID) \
		$(FPGA_IMAGE_VERSION)$(RC_STR) $(if $(DRY_RUN),-d)

build-dcp: $(ISDIRTY_CHECK) checkout-repos
	make -C $(BSG_F1_DIR)/cl_$(DESIGN_NAME)/ build

upload-agfi: $(ISDIRTY_CHECK) build-dcp upload.json

upload.json: $(ISDIRTY_CHECK) build-dcp
	-include $(BSG_F1_DIR)/cl_manycore/Makefile.dimensions
	$(BSG_F1_DIR)/scripts/afiupload/upload.py $(BUILD_PATH) $(DESIGN_NAME) \
		$(FPGA_IMAGE_VERSION)$(RC_STR) $(BSG_F1_DIR)/cl_$(DESIGN_NAME)/build/checkpoints/to_aws/cl_$(DESIGN_NAME).Developer_CL.tar \
		$(BUCKET_NAME) "BSG AWS F1 Manycore AGFI" \
		$(foreach repo,$(DEPENDENCIES),-r $(repo)@$(call hash,$(repo))) \
		-c "$(shell cat $(BSG_F1_DIR)/cl_manycore/Makefile.dimensions)" \
		$(if $(DRY_RUN),-d)

share-ami: $(ISDIRTY_CHECK)
	aws ec2 modify-image-attribute --image-id $(AMI_ID) \
		--attribute launchPermission --operation-type add \
		--user-ids $(CORNELL_USER_ID) $(UW_USER_ID)

share-afi: $(ISDIRTY_CHECK)
	aws ec2 --region us-west-2 modify-fpga-image-attribute \
		--fpga-image-id $(AFI_ID) --operation-type add \
		--user-ids $(CORNELL_USER_ID) $(UW_USER_ID)

release: AFI_NAME:=$(shell aws ec2 describe-fpga-images --fpga-image-ids=$(AFI_ID) | jq '.FpgaImages[0].Name')
release: NEW_AFI_NAME:=$(shell echo $(AFI_NAME) | sed 's/$(FPGA_IMAGE_VERSION)rc/$(FPGA_IMAGE_VERSION)/')
release: AMI_NAME:=$(shell aws ec2 describe-images --image-ids=$(AMI_ID) | jq '.Images[0].Name')
release: NEW_AMI_NAME:=$(shell echo $(AMI_NAME) | sed 's/$(FPGA_IMAGE_VERSION)rc/$(FPGA_IMAGE_VERSION)/')
release: 
	aws ec2 --region us-west-2 modify-fpga-image-attribute \
		--fpga-image-id $(AFI_ID) --name '$(NEW_AFI_NAME)' 

	aws ec2 --region us-west-2 modify-image-attribute \
		--fpga-image-id $(AMI_ID) --name '$(NEW_AMI_NAME)' 

clean:
	$(foreach dep,$(DEPENDENCIES),rm -rf $(dep)*)
	rm -rf upload.json
