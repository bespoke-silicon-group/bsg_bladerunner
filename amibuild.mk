# The following lines of code are purely for runing setup-uw. It searches for
# bsg_cadenv to configure Vivado and VCS in the environment
ifneq ("$(wildcard bsg_cadenv/cadenv.mk)","")
$(warning $(shell echo -e "\t\n\t$(ORANGE)Found bsg_cadenv. Including cadenv.mk.$(NC)"))
include bsg_cadenv/cadenv.mk
export VCS_HOME=$(VCS_MX_HOME)
endif

include project.mk

.PHONY: all update-instance riscv-tools llvm-install install env-install \
	xdma-install bsg-install help setup-aws-fpga

.DEFAULT_GOAL := all
all:help
help:
	@echo "Usage:"
	@echo "make {install|clean} "
	@echo "         install: Install all project dependencies"
	@echo "         clean: Remove all build files and repositories"

RISCV_DEPS := libmpc autoconf automake libtool curl gmp gawk bison flex \
	texinfo gperf expat-devel dtc
# AWS Installation Rules
update-instance: yum.log
yum.log: 
	echo max_connections=10 | sudo tee -a /etc/yum.conf 
	sudo yum -y install $(RISCV_DEPS) > yum.log
	sudo yum -y clean all >> yum.log
	sudo yum -y autoremove >> yum.log

setup-aws-instance: 
AWS_FPGA_REPO_URL ?= https://github.com/aws/aws-fpga.git
AWS_FPGA_REPO_DIR := $(BLADERUNNER_ROOT)/aws-fpga
setup-aws-fpga: $(AWS_FPGA_REPO_DIR).setup.log
$(AWS_FPGA_REPO_DIR).setup.log:
	git submodule update --init aws-fpga
	cd $(AWS_FPGA_REPO_DIR); patch -p0 < $(BLADERUNNER_ROOT)/aws-fpga.patch
	. $(AWS_FPGA_REPO_DIR)/hdk_setup.sh > $@

RISCV_TOOLS_DIR=$(BSG_MANYCORE_DIR)/software/riscv-tools/
RISCV_INSTALL_DIR=$(RISCV_TOOLS_DIR)/riscv-install/
riscv-tools: $(RISCV_INSTALL_DIR)
$(RISCV_INSTALL_DIR): 
	make -C $(RISCV_TOOLS_DIR) install-clean

LLVM_DIR := $(BUILD_PATH)/llvm
llvm-install: riscv-tools
	make -C $(BSG_MANYCORE_DIR)/software/mk/ -f Makefile.llvminstall LLVM_DIR=$(LLVM_DIR) RISCV_INSTALL_DIR=$(RISCV_INSTALL_DIR)

# TODO: Set permissions
XDMA_KO_FILE := /lib/modules/$(shell uname -r)/extra/xdma.ko
xdma-install:$(XDMA_KO_FILE)
$(XDMA_KO_FILE): update-instance $(AWS_FPGA_REPO_DIR).setup.log
	make -C $(AWS_FPGA_REPO_DIR)/sdk/linux_kernel_drivers/xdma
	sudo make -C $(AWS_FPGA_REPO_DIR)/sdk/linux_kernel_drivers/xdma install

bsg-install: /usr/lib64/libbsg_manycore_runtime.so.1.0
/usr/lib64/libbsg_manycore_runtime.so.1.0: $(AWS_FPGA_REPO_DIR).setup.log
	. $(AWS_FPGA_REPO_DIR)/sdk_setup.sh && make -C $(BSG_F1_DIR)/libraries
	sudo make -C $(BSG_F1_DIR)/libraries install

env-install: /etc/profile.d/profile.d_bsg.sh /etc/profile.d/agfi.sh /etc/profile.d/bsg.sh /etc/profile.d/bsg-f1.sh

/etc/profile.d/agfi.sh:
	@echo "export AGFI=$(AGFI_ID)" | sudo tee $@

/etc/profile.d/bsg.sh:
	@echo "export BSG_IP_CORES_DIR=$(BSG_IP_CORES_DIR)" | sudo tee $@
	@echo "export BASEJUMP_STL_DIR=$(BASEJUMP_STL_DIR)" | sudo tee -a $@
	@echo "export BSG_MANYCORE_DIR=$(BSG_MANYCORE_DIR)" | sudo tee -a $@
	@echo "export BSG_F1_DIR=$(BSG_F1_DIR)" | sudo tee -a $@
	@echo "export LLVM_DIR=$(HOME)/bsg_bladerunner/llvm/llvm-install" | sudo tee -a $@

/etc/profile.d/bsg-f1.sh:
	sudo mv $(subst bsg,aws,$@) $@
	sudo sed -i 's/src\/project_data/bsg_bladerunner/' $@ 

/etc/profile.d/profile.d_bsg.sh: $(AWS_FPGA_REPO_DIR).setup.log
	sudo cp $(BSG_F1_DIR)/scripts/amibuild/profile.d_bsg.sh $@
	. $(AWS_FPGA_REPO_DIR)/hdk_setup.sh
	. $(AWS_FPGA_REPO_DIR)/sdk_setup.sh

install: update-instance env-install xdma-install bsg-install riscv-tools llvm-install 
	sudo shutdown -h now # Final step

clean:
	make -C $(BSG_F1_DIR)/libraries uninstall
	sudo rm -rf $(BSG_MANYCORE_DIR) $(BSG_IP_CORES_DIR) $(BSG_F1_DIR) 
	sudo rm -rf /etc/profile.d/{profile.d_bsg.sh,agfi.sh,bsg.sh} *.log

