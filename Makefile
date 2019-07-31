DESIGN_NAME := manycore
BUCKET_NAME := bsgamibuild
CORNELL_USER_ID := 238771226843
UW_USER_ID := 339237448643

# Default to the standard origin name
ORIGIN_NAME := origin
# Parse the branch name from the repository root. This is done automatically to
# resolve a circular dependency when building
BRANCH_NAME:=$(shell git symbolic-ref --short HEAD)

# ISDIRTY_CHECK is set to dirty_repo (a target) if the repository has unpushed,
# or uncommited changes.  This is a failsafe against building an AMI/AGFI with
# changes that are not globally visible
ISDIRTY_CHECK:= $(shell git diff-index --quiet $(ORIGIN_NAME)/$(BRANCH_NAME) --ignore-submodules -- || echo dirty_check)

include Makefile.common

.PHONY: help clean setup setup-uw dirty_check \
	build-dcp build-afi print-afi share-afi \
	build-ami share-ami print-ami checkout-repos \

.DEFAULT_GOAL := help
help:
	@echo "Usage:"
	@echo "make {build-ami|build-dcp|upload-afi|clean} "
	@echo "		build-ami: Build an Amazon Machine Image (AMI) using "
	@echo "		           the AGFI and AFI in Makefile.deps "
	@echo "		build-dcp: Compile the FPGA design (locally) with the "
	@echo "		           hashes and repositories in Makefile.deps "
	@echo "		build-afi: Upload the compiled FPGA design into S3 "
	@echo "		           and create an Amazon FPGA Image (AFI) "
	@echo "		           and an Amazon Global FPGA Image ID (AGFI)"
	@echo "		print-ami: Print the AMI associated with the current"
	@echo "                    version"
	@echo "		clean: Remove all build files and repositories"

aws-fpga.setup.log:
	$(MAKE) -f Makefile.amibuild setup-aws-fpga \
		AWS_FPGA_REPO_DIR=$(BLADERUNNER_ROOT)/aws-fpga

$(DEPENDENCIES): aws-fpga.setup.log
	git submodule update --init $@

dirty_check:
	@echo "Error! this repository is dirty. Push changes before building"
	@exit 1

CL_MANYCORE_TARBALL := $(BSG_F1_DIR)/cl_$(DESIGN_NAME)/build/checkpoints/to_aws/cl_$(DESIGN_NAME).Developer_CL.tar

build-tarball: $(CL_MANYCORE_TARBALL)
$(CL_MANYCORE_TARBALL): $(DEPENDENCIES)
	make -C $(BSG_F1_DIR)/cl_$(DESIGN_NAME)/ build \
		FPGA_IMAGE_VERSION=$(FPGA_IMAGE_VERSION)

build-afi: $(CL_MANYCORE_TARBALL) upload.json

ifneq ("$(wildcard $(BSG_F1_DIR)/cl_manycore)","")
include $(BSG_F1_DIR)/cl_manycore/Makefile.machine.include
endif
# CONFIG STRING uses variables defined in Makefile.machine.include
CONFIG_STRING  = BSG_MACHINE_GLOBAL_X = $(BSG_MACHINE_GLOBAL_X),
CONFIG_STRING += BSG_MACHINE_GLOBAL_Y = $(BSG_MACHINE_GLOBAL_Y),
CONFIG_STRING += CL_MANYCORE_DIM_X = $(CL_MANYCORE_DIM_X),
CONFIG_STRING += CL_MANYCORE_DIM_Y = $(CL_MANYCORE_DIM_Y)
upload.json: $(CL_MANYCORE_TARBALL)
	$(BSG_F1_DIR)/scripts/afiupload/upload.py $(BUILD_PATH) $(DESIGN_NAME) \
		$(FPGA_IMAGE_VERSION) $< \
		$(BUCKET_NAME) "BSG AWS F1 Manycore AFI" \
		$(addprefix -r ,$(DEPENDENCIES)) \
		-c "$(CONFIG_STRING)" \
		$(if $(DRY_RUN),-d)

share-afi: $(ISDIRTY_CHECK)
	aws ec2 --region us-west-2 modify-fpga-image-attribute \
		--fpga-image-id $(AFI_ID) --operation-type add \
		--user-ids $(CORNELL_USER_ID) $(UW_USER_ID)

define get_current_ami
	aws ec2 describe-images --owner=self \
	--filters "Name=tag:Version,Values=$(FPGA_IMAGE_VERSION)" \
	--query 'Images[0].ImageId' | sed 's/"//g'
endef

print-ami: $(ISDIRTY_CHECK)
	@echo $(shell $(call get_current_ami))

build-ami: $(ISDIRTY_CHECK) $(DEPENDENCIES)
	$(BSG_F1_DIR)/scripts/amibuild/build.py Bladerunner \
		bsg_bladerunner@$(BRANCH_NAME) $(AFI_ID) \
		$(FPGA_IMAGE_VERSION) $(if $(DRY_RUN),-d)

share-ami: $(ISDIRTY_CHECK)
	$(eval AMI_ID :=  $(shell $(call get_current_ami)))
	aws ec2 modify-image-attribute --image-id $(AMI_ID) \
		--attribute launchPermission --operation-type add \
		--user-ids $(CORNELL_USER_ID) $(UW_USER_ID)


bsg_cadenv:
	git clone git@bitbucket.org:taylor-bsg/bsg_cadenv.git	

setup: $(DEPENDENCIES) 
	$(MAKE) -f Makefile.amibuild riscv-tools

setup-uw: bsg_cadenv setup 


clean:
	rm -rf upload.json

squeakyclean:
	git submodule deinit $(DEPENDENCIES)
	git submodule deinit aws-fpga
	rm -rf aws-fpga.setup.log
	rm -rf bsg_cadenv
