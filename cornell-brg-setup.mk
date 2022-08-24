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

riscv-tools: submodule_init
	ln -s $(RISCV_INSTALL_PATH) ../bsg_bladerunner_cornell-brg/$(RISCV_INSTALL_PATH)

llvm: submodule_init
	ln -s $(LLVM_INSTALL_PATH) ../bsg_bladerunner_cornell-brg/$(LLVM_INSTALL_PATH)

riscv-toolchain: riscv-tools llvm

basejump_init: submodule_init
	$(MAKE) -C basejump_stl/imports DRAMSim3

manycore_init: submodule_init
	$(MAKE) -C bsg_manycore/ checkout_submodules

submodule_init:
	git submodule update --init
