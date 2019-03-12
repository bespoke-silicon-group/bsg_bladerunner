
include Makefile.deps

.PHONY: checkout-repos build-dcp build-ami upload-agfi build-ami clean update-instance riscv-tools llvm-install install
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
$(foreach dep,$(DEPENDENCIES),$(dep)_$(call hash,$(dep)))
endef

# Define a makefile rule for the repo $(1)
# Each of the repos (and resulting directories) is named
# "<repo>_<commit_hash>". The rule for each clones the repo into the
# directory named with the commit hash and resets to the commit pointed
# to by the hash.
# Also, define <repo_name>_DIR as a variable
define nested-rule
export $(call upper, $(1))_DIR=$(BUILD_PATH)/$(1)_$(call hash, $(1))

$(1)_$(call hash,$(1)):
	git clone https://bitbucket.org/taylor-bsg/$(1).git $(BUILD_PATH)/$(1)_$(call hash,$(1))
	cd $(BUILD_PATH)/$(1)_$(call hash,$(1)) && git checkout $(call hash,$(1))
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
update-instance: yum.log
yum.log:
	echo max_connections=10 | sudo tee -a /etc/yum.conf 
	sudo yum -y update > yum.log
	sudo yum -y clean all >> yum.log
	sudo yum -y autoremove >> yum.log

AWS_FPGA_REPO_DIR ?= /home/centos/src/project_data/aws-fpga
$(AWS_FPGA_REPO_DIR): 
	git clone https://github.com/aws/aws-fpga.git $(AWS_FPGA_REPO_DIR)
	cd $(AWS_FPGA_REPO_DIR); git checkout $(AWS_FPGA_VERSION)

RISCV_INSTALL_DIR=$(BSG_MANYCORE_DIR)/software/riscv-tools/riscv-install/
riscv-tools: update-instance $(RISCV_INSTALL_DIR)
$(RISCV_INSTALL_DIR):
	sudo yum -y install libmpc autoconf automake libtool curl gmp gawk bison flex texinfo gperf expat-devel
	make -C $(BSG_MANYCORE_DIR)/software/riscv-tools checkout-all
	make -C $(BSG_MANYCORE_DIR)/software/riscv-tools build-riscv-tools 2>&1 > build.log

LLVM_DIR := $(BUILD_PATH)/llvm
llvm-install: riscv-tools
	# Install cmake
	wget https://github.com/Kitware/CMake/releases/download/v3.14.0-rc4/cmake-3.14.0-rc4-Linux-x86_64.sh -O cmake-install.sh
	chmod +x cmake-install.sh && sudo ./cmake-install.sh --skip-license --prefix=/usr/local
	rm cmake-install.sh
	mkdir -p $(LLVM_DIR)/llvm-build && mkdir -p $(LLVM_DIR)/llvm-install
	# Clone LLVM sources
	cd $(LLVM_DIR) && wget http://releases.llvm.org/7.0.1/llvm-7.0.1.src.tar.xz && \
	    tar -xf llvm-7.0.1.src.tar.xz && mv llvm-7.0.1.src llvm-src && rm llvm-7.0.1.src.tar.xz
	# Clone clang sources
	cd $(LLVM_DIR)/llvm-src/tools && wget http://releases.llvm.org/7.0.1/cfe-7.0.1.src.tar.xz \
	    && tar -xf cfe-7.0.1.src.tar.xz && mv cfe-7.0.1.src clang && rm cfe-7.0.1.src.tar.xz
	# -DGCC_INSTALL_PREFIX, -DDEFAULT_SYSROOT, -DLLVM_DEFAULT_TARGET_TRIPLE
	# aren't strictly necessary, but otherwise there'd be more options to
	# pass on the command line for clang. We Only need X86 and RISCV targets.
	cd $(LLVM_DIR)/llvm-build \
	    && cmake -DCMAKE_BUILD_TYPE="Debug" \
	    -DLLVM_TARGETS_TO_BUILD="X86" \
	    -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD="RISCV" \
	    -DBUILD_SHARED_LIBS=True \
	    -DLLVM_USE_SPLIT_DWARF=True \
	    -DLLVM_OPTIMIZED_TABLEGEN=True \
	    -DCMAKE_INSTALL_PREFIX="$(LLVM_DIR)/llvm-install" \
	    -DGCC_INSTALL_PREFIX="$(LLVM_DIR)/local" \
	    -DDEFAULT_SYSROOT="$(RISCV_INSTALL_DIR)/riscv32-unknown-elf" \
	    -DLLVM_DEFAULT_TARGET_TRIPLE="riscv32-unknown-elf" \
	    ../llvm-src
	cd  $(LLVM_DIR)/llvm-build && cmake --build . -- -j12 && sudo make install
	rm -rf $(LLVM_DIR)/llvm-build $(LLVM_DIR)/llvm-src

# TODO: Set permissions
xdma-driver: update-instance $(AWS_FPGA_REPO_DIR)
	make -C $(AWS_FPGA_REPO_DIR)/sdk/linux_kernel_drivers/xdma
	sudo make -C $(AWS_FPGA_REPO_DIR)/sdk/linux_kernel_drivers/xdma install

bsg-drivers: update-instance $(AWS_FPGA_REPO_DIR)
	make -C $(BSG_F1_DIR)/cl_manycore/drivers
	sudo make -C $(BSG_F1_DIR)/cl_manycore/drivers install

bsg-libraries: bsg-drivers $(AWS_FPGA_REPO_DIR)
	make -C $(BSG_F1_DIR)/cl_manycore/libraries
	sudo make -C $(BSG_F1_DIR)/cl_manycore/libraries install

/etc/profile.d/agfi.sh:
	@echo "export AGFI=$(AGFI_ID)" | sudo tee $@

/etc/profile.d/profile.d_bsg.sh: $(AWS_FPGA_REPO_DIR) checkout-repos
	sudo cp $(BSG_F1_DIR)/scripts/amibuild/profile.d_bsg.sh $@
	. $(AWS_FPGA_REPO_DIR)/hdk_setup.sh
	. $(AWS_FPGA_REPO_DIR)/sdk_setup.sh

setup_env: /etc/profile.d/profile.d_bsg.sh /etc/profile.d/agfi.sh

install: checkout-repos setup_env xdma-driver bsg-libraries riscv-tools llvm-install
	sudo shutdown -h now # Final step

clean-ami:
	make -C $(BSG_F1_DIR)/cl_manycore/libraries uninstall
	make -C $(BSG_F1_DIR)/cl_manycore/drivers uninstall
	sudo rm -rf $(BSG_MANYCORE_DIR) $(BSG_IP_CORES_DIR) $(BSG_F1_DIR) yum.log
	sudo rm -rf /etc/profile.d/{profile.d_bsg.sh,agfi.sh}
