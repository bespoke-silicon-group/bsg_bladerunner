# Optional, pinned HammerBlade LLVM 22 compiler; GNU/newlib remains required.
# From bsg_bladerunner: gmake -f llvm22.mk llvm22-install LLVM22_JOBS=8
include project.mk

LLVM22_REPOSITORY ?= https://github.com/bespoke-silicon-group/llvm-project.git
LLVM22_REVISION ?= 7286564fede1bf7b8243bb51bfa039731aa62da6
LLVM22_SOURCE_DIR ?= $(BLADERUNNER_ROOT)/llvm-project
LLVM22_BUILD_DIR ?= $(BLADERUNNER_ROOT)/build/llvm22
LLVM22_INSTALL_DIR ?= $(BLADERUNNER_ROOT)/install/llvm22
LLVM22_JOBS ?= 8
LLVM22_CMAKE ?= cmake
LLVM22_MAKE ?= $(shell command -v $(MAKE))
ifeq ($(shell uname -s),Darwin)
LLVM22_HOST_CC ?= /usr/bin/clang
LLVM22_HOST_CXX ?= /usr/bin/clang++
else
LLVM22_HOST_CC ?= cc
LLVM22_HOST_CXX ?= c++
endif

.DEFAULT_GOAL := llvm22-install
.PHONY: llvm22-source llvm22-configure llvm22-build llvm22-install

$(LLVM22_SOURCE_DIR)/llvm/CMakeLists.txt:
	@test ! -e "$(LLVM22_SOURCE_DIR)" || { echo "Refusing to replace an incomplete LLVM source directory" >&2; exit 1; }
	git clone --filter=blob:none --no-checkout "$(LLVM22_REPOSITORY)" "$(LLVM22_SOURCE_DIR)"
	git -C "$(LLVM22_SOURCE_DIR)" fetch origin "$(LLVM22_REVISION)"
	git -C "$(LLVM22_SOURCE_DIR)" switch --detach "$(LLVM22_REVISION)"

llvm22-source: $(LLVM22_SOURCE_DIR)/llvm/CMakeLists.txt
	@test "$$(git -C "$(LLVM22_SOURCE_DIR)" rev-parse HEAD)" = "$(LLVM22_REVISION)" || { echo "LLVM source does not match LLVM22_REVISION; select a reviewed revision explicitly" >&2; exit 1; }
	git -C "$(LLVM22_SOURCE_DIR)" diff --exit-code HEAD --

llvm22-configure: llvm22-source
	$(LLVM22_CMAKE) -S "$(LLVM22_SOURCE_DIR)/llvm" -B "$(LLVM22_BUILD_DIR)" \
	  -G "Unix Makefiles" -DCMAKE_MAKE_PROGRAM="$(LLVM22_MAKE)" \
	  -DCMAKE_C_COMPILER="$(LLVM22_HOST_CC)" -DCMAKE_CXX_COMPILER="$(LLVM22_HOST_CXX)" \
	  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$(LLVM22_INSTALL_DIR)" \
	  -DLLVM_ENABLE_PROJECTS=clang -DLLVM_TARGETS_TO_BUILD=RISCV \
	  -DLLVM_ENABLE_ASSERTIONS=OFF -DLLVM_INCLUDE_TESTS=OFF \
	  -DLLVM_INCLUDE_EXAMPLES=OFF -DLLVM_INCLUDE_BENCHMARKS=OFF \
	  -DLLVM_ENABLE_ZLIB=OFF -DLLVM_ENABLE_ZSTD=OFF -DLLVM_ENABLE_LIBXML2=OFF \
	  -DLLVM_ENABLE_CURL=OFF -DLLVM_ENABLE_HTTPLIB=OFF -DLLVM_ENABLE_FFI=OFF

llvm22-build: llvm22-configure
	$(LLVM22_CMAKE) --build "$(LLVM22_BUILD_DIR)" --parallel $(LLVM22_JOBS) \
	  --target clang opt llc llvm-objcopy llvm-ar llvm-mca

llvm22-install: llvm22-build
	$(LLVM22_CMAKE) --build "$(LLVM22_BUILD_DIR)" --parallel $(LLVM22_JOBS) \
	  --target install-clang install-clang-resource-headers install-opt install-llc \
	  install-llvm-objcopy install-llvm-ar install-llvm-mca
	"$(LLVM22_INSTALL_DIR)/bin/clang" --version
	"$(LLVM22_INSTALL_DIR)/bin/llc" --version
