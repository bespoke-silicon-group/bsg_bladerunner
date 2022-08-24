BLADERUNNER_PATH=$(shell git rev-parse --show-toplevel)
RISCV_INSTALL_PATH=bsg_manycore/software/riscv-tools/riscv-install
LLVM_INSTALL_PATH=bsg_manycore/software/riscv-tools/llvm

.PHONY: riscv-tools
.PHONY: llvm
.PHONY: riscv-toolchain
.PHONY: basejump_init
.PHONY: manycore_init
.PHONY: submodule_init
.PHONY: all

all: bsg_cadenv
all: riscv-toolchain
all: basejump_init
all: manycore_init

bsg_cadenv:
	git clone git@github.com:bespoke-silicon-group/bsg_cadenv

$(RISCV_INSTALL_PATH): submodule_init
	rm -f $@
	ln -s $(BLADERUNNER_PATH)/../bsg_bladerunner_cornell-brg/$(RISCV_INSTALL_PATH) $@	

$(LLVM_INSTALL_PATH): submodule_init
	rm -f $@
	ln -s $(BLADERUNNER_PATH)/../bsg_bladerunner_cornell-brg/$(LLVM_INSTALL_PATH) $@

riscv-toolchain: $(RISCV_INSTALL_PATH) $(LLVM_INSTALL_PATH)

basejump_init: submodule_init
	$(MAKE) -C basejump_stl/imports DRAMSim3

manycore_init: submodule_init
	$(MAKE) -C bsg_manycore/ checkout_submodules

submodule_init:
	git submodule update --init
