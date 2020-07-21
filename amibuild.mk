# Copyright (c) 2019, University of Washington All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
# 
# Redistributions of source code must retain the above copyright notice, this list
# of conditions and the following disclaimer.
# 
# Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
# 
# Neither the name of the copyright holder nor the names of its contributors may
# be used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# The following lines of code are purely for runing setup-uw. It searches for
# bsg_cadenv to configure Vivado and VCS in the environment
ifneq ("$(wildcard bsg_cadenv/cadenv.mk)","")
$(warning $(shell echo -e "\t\n\t$(ORANGE)Found bsg_cadenv. Including cadenv.mk.$(NC)"))
include bsg_cadenv/cadenv.mk
export VCS_HOME=$(VCS_MX_HOME)
endif

include project.mk

.PHONY: all update-instance riscv-tools install env-install \
	xdma-install bsg-install help setup-aws-fpga

.DEFAULT_GOAL := all
all:help
help:
	@echo "Usage:"
	@echo "make {install|clean} "
	@echo "         install: Install all project dependencies"
	@echo "         clean: Remove all build files and repositories"

RISCV_DEPS := libmpc autoconf automake libtool curl gmp gawk bison flex \
	texinfo gperf expat-devel dtc cmake3
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
	. $(AWS_FPGA_REPO_DIR)/hdk_setup.sh | tee $@.temp && mv $@.temp $@

RISCV_TOOLS_DIR=$(BSG_MANYCORE_DIR)/software/riscv-tools/
RISCV_INSTALL_DIR=$(RISCV_TOOLS_DIR)/riscv-install/
riscv-tools: $(RISCV_INSTALL_DIR)
$(RISCV_INSTALL_DIR): 
	make -j8 -C $(RISCV_TOOLS_DIR) install-clean

# TODO: Set permissions
XDMA_KO_FILE := /lib/modules/$(shell uname -r)/extra/xdma.ko
xdma-install:$(XDMA_KO_FILE)
$(XDMA_KO_FILE): update-instance $(AWS_FPGA_REPO_DIR).setup.log
	make -C $(AWS_FPGA_REPO_DIR)/sdk/linux_kernel_drivers/xdma
	sudo make -C $(AWS_FPGA_REPO_DIR)/sdk/linux_kernel_drivers/xdma install

bsg-install: /usr/lib64/libbsg_manycore_runtime.so.1.0
/usr/lib64/libbsg_manycore_runtime.so.1.0: $(AWS_FPGA_REPO_DIR).setup.log
	. $(AWS_FPGA_REPO_DIR)/sdk_setup.sh && make -C $(BSG_F1_DIR)/libraries
	sudo -E make -C $(BSG_F1_DIR)/libraries install BSG_PLATFORM=aws-fpga AGFI=$(AGFI_ID)

env-install: /etc/profile.d/profile.d_bsg.sh /etc/profile.d/agfi.sh /etc/profile.d/bsg.sh /etc/profile.d/bsg-f1.sh

/etc/profile.d/agfi.sh:
	@echo "export AGFI=$(AGFI_ID)" | sudo tee $@

/etc/profile.d/bsg.sh:
	@echo "export BSG_IP_CORES_DIR=$(BSG_IP_CORES_DIR)" | sudo tee $@
	@echo "export BASEJUMP_STL_DIR=$(BASEJUMP_STL_DIR)" | sudo tee -a $@
	@echo "export BSG_MANYCORE_DIR=$(BSG_MANYCORE_DIR)" | sudo tee -a $@
	@echo "export BSG_F1_DIR=$(BSG_F1_DIR)" | sudo tee -a $@
	@echo "export LLVM_DIR=$(RISCV_TOOLS_DIR)/llvm/llvm-install" | sudo tee -a $@

/etc/profile.d/bsg-f1.sh:
	sudo mv $(subst bsg,aws,$@) $@
	sudo sed -i 's/src\/project_data/bsg_bladerunner/' $@ 

/etc/profile.d/profile.d_bsg.sh: $(AWS_FPGA_REPO_DIR).setup.log
	sudo cp $(BLADERUNNER_ROOT)/scripts/amibuild/profile.d_bsg.sh $@
	. $(AWS_FPGA_REPO_DIR)/hdk_setup.sh
	. $(AWS_FPGA_REPO_DIR)/sdk_setup.sh

install: update-instance env-install xdma-install bsg-install riscv-tools
	sudo shutdown -h now # Final step

clean:
	make -C $(BSG_F1_DIR)/libraries uninstall
	sudo rm -rf $(BSG_MANYCORE_DIR) $(BSG_IP_CORES_DIR) $(BSG_F1_DIR) 
	sudo rm -rf /etc/profile.d/{profile.d_bsg.sh,agfi.sh,bsg.sh} *.log

