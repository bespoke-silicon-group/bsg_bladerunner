#!/bin/env bash
cd /
git clone https://github.com/bespoke-silicon-group/llvm-project.git
cd /llvm-project && git fetch && git checkout hb-dev

mkdir /llvm-build && cd /llvm-build
cmake -G Ninja -DCMAKE_BUILD_TYPE="Debug" -DCMAKE_INSTALL_PREFIX=/llvm_install -DCMAKE_C_COMPILER=/usr/bin/gcc -DCMAKE_CXX_COMPILER=/usr/bin/g++ -DLLVM_TARGETS_TO_BUILD="X86;RISCV" -DBUILD_SHARED_LIBS=True -DLLVM_USE_SPLIT_DWARF=True -DLLVM_OPTIMIZED_TABLEGEN=True /llvm-project/llvm
cmake --build . --target install -- -j 16
