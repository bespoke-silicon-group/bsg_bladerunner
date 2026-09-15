# Fresh macOS HammerBench setup: GCC and LLVM 22, physical 16×8

Use a path without spaces. Install the Xcode Command Line Tools and the
Homebrew prerequisites in the top-level README, including GNU Make (`gmake`),
Python 3, `wget`, and `xz`. These instructions build source dependencies from
the pinned checkout; they do not require another working HammerBlade installation.

## Source and toolchain

```sh
git clone https://github.com/bespoke-silicon-group/bsg_bladerunner.git
cd bsg_bladerunner
git -c url.https://github.com/.insteadOf=git@github.com: submodule update --init --recursive
export BR="$PWD"
export REPLICANT_PATH="$BR/bsg_replicant"
export BSG_PLATFORM=bigblade-verilator
export BSG_MACHINE_PATH="$REPLICANT_PATH/machines/pod_X1Y1_ruche_X16Y8_hbm_one_pseudo_channel"
export VERILATOR_ROOT="$BR/verilator"
export VERILATOR="$VERILATOR_ROOT/bin/verilator"
export VERILATOR_THREADS=1

gmake -j6 verilator-exe
gmake -f amibuild.mk riscv-gcc COMPILING_THREADS=6
gmake -f llvm22.mk llvm22-install LLVM22_JOBS=6
gmake -f simulator.mk -j6 sim-exec
gmake -f simulator.mk -j6 sim-profile
```

`llvm22.mk` pins the merged HammerBlade LLVM 22.1.8 source at
[`7286564fede1bf7b8243bb51bfa039731aa62da6`](https://github.com/bespoke-silicon-group/llvm-project/commit/7286564fede1bf7b8243bb51bfa039731aa62da6)
([LLVM #10](https://github.com/bespoke-silicon-group/llvm-project/pull/10)).
Its source tree is identical to the validated policy foundation `dae290d28617`;
it does not include the pending runtime-unrolling candidate in LLVM #11.
It uses the macOS host Clang,
builds only the RISC-V backend and required tools, and installs them under
`install/llvm22`. GNU GCC 9.2/newlib/binutils remain necessary for runtime
objects, assembler sources, and final linking with either device compiler.
The old Linux/LLVM 10 installer is not used. All source/build/install directories
and host compilers in `llvm22.mk` can be overridden explicitly.

Existing installations are not updated by merging a source pin. The source
target rejects a checkout at another revision rather than overwriting it.
Preserve existing compiler products and use fresh paths for an isolated install:

```sh
gmake -f llvm22.mk llvm22-install LLVM22_JOBS=6 \
  LLVM22_SOURCE_DIR="$BR/llvm-project-policy" \
  LLVM22_BUILD_DIR="$BR/build/llvm22-policy" \
  LLVM22_INSTALL_DIR="$BR/install/llvm22-policy"
```

Select that installation explicitly with `RISCV_LLVM_PATH` when building
applications. The 2026-09-12 fresh-source audit and its 68 passing GCC/LLVM
application executions used the earlier LLVM `0ee3b2946133`. Those measurements
retain their original compiler identity; this pin update is not a new benchmark
run or an automatic update of previously installed binaries.

The selected hardware has one physical 16×8 pod, 32 blocking 32-KiB v-cache
banks, iPoly hashing enabled, and hardware barriers enabled. It uses the
configured DRAMSim3 HBM2 model. Do not replace it with a tiny machine while
interpreting 16×8 results. `VERILATOR_THREADS=1` selects one host worker per
process; it does not reduce the 128 simulated cores.

Build the shared models before concurrent application runs. Do not change the
machine or thread count, run `clean`, or rebuild shared libraries while those
runs are active. Independent runs may share these read-only products but must
have separate writable application/run directories.

## Application and inputs

```sh
export HB="$REPLICANT_PATH/examples/hb_hammerbench"
git -C "$HB" worktree add --detach "$BR/hb-gcc" HEAD
git -C "$HB" worktree add --detach "$BR/hb-llvm" HEAD
```

For **each** worktree, set `HB` to its absolute path and follow
[`hb_hammerbench/docs/compiler-comparison.md`](../bsg_replicant/examples/hb_hammerbench/docs/compiler-comparison.md).
The guide covers the pinned AES submodule, graph downloads and preprocessing,
all stock test cases, and the exact GCC/LLVM selection and run commands.
Keeping compiler products separate avoids stale objects: changing a Make
variable alone does not invalidate an existing `.rvo` object.

To share input preparation, generate data in one fresh checkout and symlink
only completed graph `inputs/*.txt` files into the second. Do not share generated
case directories or writable simulator logs. Record input hashes if comparing
compilers. The 2026-09-12 audit exercised all three applications' preprocessing
Make targets, rather than importing inputs from an older installation.

## Timing

Use `/usr/bin/time -p` for macOS wall time. Compare target cycles, not wall
time: parallel host jobs contend for resources without changing simulated
clock timing. The kernel-marker envelope is the latest finish minus earliest
start across the matched 128 tile markers. `simple_stats.csv` from `exec.log`
contains timestamps in ps (666 ps/core cycle for this machine); `profile.log`
also emits `vanilla_stats.csv` with `global_ctr` and v-cache counters. Use
matched kernel start/finish markers, not a process shutdown timestamp or a sum
of 128 core-cycle intervals. Warm/cold cache, iteration count, and logical pod
selection are part of each stock test name and must match between compilers.
