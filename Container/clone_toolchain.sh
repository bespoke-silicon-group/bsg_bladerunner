#!/bin/env bash
TOOLCHAIN_REPO=riscv-gnu-toolchain
TOOLCHAIN_URL=https://github.com/bespoke-silicon-group/$TOOLCHAIN_REPO
TOOLCHAIN_VERSION=656708846d723936eb5ba2648f6f919608a8ccaf

SPIKE_REPO=riscv-isa-sim
SPIKE_URL=https://github.com/riscv/riscv-isa-sim.git
SPIKE_PATCH_URL=https://raw.githubusercontent.com/bespoke-silicon-group/bsg_manycore/428100202eddc7035c24be4e3390237784fc80bc/software/riscv-tools/spike.patch
SPIKE_PATCH=spike.patch
SPIKE_PATCH_GCC_URL=https://raw.githubusercontent.com/bespoke-silicon-group/bsg_manycore/428100202eddc7035c24be4e3390237784fc80bc/software/riscv-tools/spike-gcc.patch
SPIKE_PATCH_GCC=spike-gcc.patch
SPIKE_TAG=v1.0.0

cd /
git clone $TOOLCHAIN_URL
cd $TOOLCHAIN_REPO && git checkout $TOOLCHAIN_VERSION && cd /
cd $TOOLCHAIN_REPO && git submodule update --init --recursive -j 16 && cd /

git clone --recursive $SPIKE_URL
wget $SPIKE_PATCH_URL -O /$SPIKE_PATCH
wget $SPIKE_PATCH_GCC_URL -O /$SPIKE_PATCH_GCC
ls /
cd $SPIKE_REPO && git checkout tags/$SPIKE_TAG && git apply /$SPIKE_PATCH &&  git apply /$SPIKE_PATCH_GCC && cd /
