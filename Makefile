
include Makefile.deps

.PHONY: checkout-repos build-dcp upload-agfi build-ami
all: build-ami

BUILD_PATH := $(shell pwd)
DESIGN_NAME := manycore
BUCKET_NAME := bsgamibuild

define upper
$(shell echo $(1) | tr [:lower:] [:upper:])
endef

# Get the hash associated with $(1) in Makefile.deps.
# hash(bsg_manycore) returns the git commit hash for bsg_manycore
define hash
$($(call upper,$(1)_HASH))
endef


# Generate a list of the repositories with their commit hashes appended
define repo-list
$(foreach dep,$(DEPENDENCIES),$(dep)@$(call hash,$(dep)))
endef

# Define a makefile rule for the repo $(1)
# Each of the repos (and resulting directories) is named
# "<repo>@<commit_hash>". The rule for each clones the repo into the
# directory named with the commit hash and resets to the commit pointed
# to by the hash.
# Also, define <repo_name>_DIR as a variable
define nested-rule
export $(call upper, $(1))_DIR=$(BUILD_PATH)/$(1)\@$(call hash, $(1))

$(1)@$(call hash,$(1)):
	git clone https://bitbucket.org/taylor-bsg/$(1).git $(BUILD_PATH)/$(1)@$(call hash,$(1))
	cd $(BUILD_PATH)/$(1)@$(call hash,$(1)) && git checkout $(call hash,$(1))
endef

# Generate a Makefile goal for each of the repositories
$(foreach dep,$(DEPENDENCIES),$(eval $(call nested-rule,$(dep))))

checkout-repos: $(call repo-list)

build-ami: checkout-repos upload-agfi
	$(BSG_F1_DIR)/scripts/amibuild/build.py bsg_bladerunner_release@master -u upload.json

build-dcp: checkout-repos
	make -C $(BSG_F1_DIR)/cl_$(DESIGN_NAME)/ build

upload-agfi: build-dcp upload.json

upload.json:
	$(BSG_F1_DIR)/scripts/afiupload/upload.py $(BUILD_PATH) $(DESIGN_NAME) \
	    $(FPGA_IMAGE_VERSION) $(BSG_F1_DIR)/cl_$(DESIGN_NAME)/build/checkpoints/to_aws/cl_$(DESIGN_NAME).Developer_CL.tar \
	    $(BUCKET_NAME) "BSG AWS F1 Manycore AGFI" $(foreach repo,$(DEPENDENCIES),-r $(repo)@$(call hash,$(repo)))

clean:
	$(foreach dep,$(DEPENDENCIES),rm -rf $(dep)*)
	rm -rf upload.json


# AWS Installation Rules
update-instance: 
	sudo yum -y update
	sudo yum -y clean all
	sudo yum -y autoremove

AWS_FPGA_REPO_DIR ?= /home/centos/src/project_data/aws-fpga
$(AWS_FPGA_REPO_DIR): update-instance
	git clone https://github.com/aws/aws-fpga.git $(AWS_FPGA_REPO_DIR)
	cd $(AWS_FPGA_REPO_DIR); git checkout $(AWS_FPGA_VERSION)
	. $(AWS_FPGA_REPO_DIR)/hdk_setup.sh
	. $(AWS_FPGA_REPO_DIR)/sdk_setup.sh

riscv-tools: update-instance
	sudo yum -y install libmpc autoconf automake libtool curl gmp gawk bison flex texinfo gperf
	make -C $(BSG_MANYCORE_DIR)/software/riscv-tools checkout-all
	make -C $(BSG_MANYCORE_DIR)/software/riscv-tools build-riscv-tools

# TODO: Set permissions
xdma-driver: update-instance $(AWS_FPGA_REPO_DIR)
	make -C $(AWS_FPGA_REPO_DIR)/sdk/linux_kernel_drivers/xdma
	sudo make -C $(AWS_FPGA_REPO_DIR)/sdk/linux_kernel_drivers/xdma install

/etc/profile.d/agfi.sh:
	@echo "export AGFI=$(AGFI_ID)" | sudo tee $@

/etc/profile.d/profile.d_bsg.sh: $(AWS_FPGA_REPO_DIR) checkout-repos
	sudo cp $(BSG_F1_DIR)/scripts/amibuild/profile.d_bsg.sh $@

setup_env: /etc/profile.d/profile.d_bsg.sh /etc/profile.d/agfi.sh

install: checkout-repos setup_env xdma-driver riscv-tools
	sudo shutdown -h now # Final step
