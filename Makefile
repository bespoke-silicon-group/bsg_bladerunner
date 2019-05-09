DESIGN_NAME := manycore
BUCKET_NAME := bsgamibuild
CORNELL_USER_ID := 238771226843
UW_USER_ID := 339237448643

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


build-ami: checkout-repos
	$(BSG_F1_DIR)/scripts/amibuild/build.py bsg_bladerunner@$(RELEASE_BRANCH) $(AFI_ID) $(FPGA_IMAGE_VERSION)

build-dcp: checkout-repos
	make -C $(BSG_F1_DIR)/cl_$(DESIGN_NAME)/ build

upload-agfi: build-dcp upload.json

upload.json: build-dcp
	-include $(BSG_F1_DIR)/cl_manycore/Makefile.dimensions
	$(BSG_F1_DIR)/scripts/afiupload/upload.py $(BUILD_PATH) $(DESIGN_NAME) \
		$(FPGA_IMAGE_VERSION) $(BSG_F1_DIR)/cl_$(DESIGN_NAME)/build/checkpoints/to_aws/cl_$(DESIGN_NAME).Developer_CL.tar \
		$(BUCKET_NAME) "BSG AWS F1 Manycore AGFI" \
		$(foreach repo,$(DEPENDENCIES),-r $(repo)@$(call hash,$(repo))) \
		-c "Version: $(FPGA_IMAGE_VERSION) $(shell cat $(BSG_F1_DIR)/cl_manycore/Makefile.dimensions)"

share-ami:
	aws ec2 modify-image-attribute --image-id $(AMI_ID) \
		--attribute launchPermission --operation-type add \
		--user-ids $(CORNELL_USER_ID) $(UW_USER_ID)

share-afi:
	aws ec2 --region us-west-2 modify-fpga-image-attribute \
		--fpga-image-id $(AFI_ID) --operation-type add \
		--user-ids $(CORNELL_USER_ID) $(UW_USER_ID)

clean:
	$(foreach dep,$(DEPENDENCIES),rm -rf $(dep)*)
	rm -rf upload.json
