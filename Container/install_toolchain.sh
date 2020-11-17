#!/bin/env bash
TARGET_ARCH=rv32imaf
TARGET_ABI=ilp32f
TARGET_CFLAGS='-fno-common'

TOOLCHAIN_REPO=riscv-gnu-toolchain
SPIKE_REPO=riscv-isa-sim

set -e

# Build toolchain
cd /$TOOLCHAIN_REPO
./configure --prefix /usr --disable-linux --with-arch=$TARGET_ARCH --with-abi=$TARGET_ABI
make -j 16 CFLAGS_FOR_TARGET_EXTRA=$TARGET_CFLAGS
make install

# Build spike
cd /$SPIKE_REPO
./configure --prefix /usr --enable-commitlog
make -j 16
make install
