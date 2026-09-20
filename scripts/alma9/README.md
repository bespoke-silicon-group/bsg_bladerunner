# HammerBlade on AlmaLinux 9 (x86-64)

Install ordinary build tools through DNF, then build Verilator, the customized
RISC-V compiler and Python dependencies inside each user's HammerBlade checkout.
Different users and experiments can keep independent versions. These scripts
perform no drive discovery, mounting, storage provisioning or browser launch.

## Bootstrap

Start with a complete release bundle or this directory in a committed Bladerunner
clone. If GitHub access is not configured, run `bash setup-github.sh` in a terminal;
complete its device-code authorization on another computer. It installs Git/GitHub
CLI if needed and checks private handbook access. Personal credentials are never
part of the bundle. `--packages-only` skips personal authentication.

Run as the intended ordinary Unix user:

```sh
bash install-alma9-prerequisites.sh
HB_MACHINE_NAME=pod_X1Y1_ruche_X16Y8_hbm_one_pseudo_channel \
  bash setup-hammerblade.sh all "$HOME/hb-16x8"
bash validate-hammerblade.sh "$HOME/hb-16x8"
```

The prerequisite installer uses sudo only for DNF, enables AlmaLinux CRB, and
installs explicit packages in standard system locations. It includes `lz4-devel`
for debug FST waveforms, packaged Clang/LLVM, GCC Toolset 15, NUMA tools and perf.
Use `--dry-run` to inspect the package list. Package versions follow the configured
AlmaLinux repositories; validation records versions without freezing OS updates.

The setup pins Bladerunner to the commit containing this script. A standalone
bundle instead includes `bladerunner-revision.txt` with that exact commit. The
parent gitlinks select compatible BaseJump, DRAMSim3, Manycore, Replicant,
HammerBench and Verilator sources; do not update these components independently.
The customized GNU toolchain is pinned to
`656708846d723936eb5ba2648f6f919608a8ccaf` and its own component gitlinks.
Python dependencies are pinned in `hammerblade-python-requirements.txt`.

No LLVM device compiler is required. The narrow GCC build target produces BSG
GCC 9.2.0/newlib; the broad historical `riscv-tools` target also builds older
LLVM/Spike components. The handbook's LLVM 22 device compiler remains optional.

## Checkout and compiler selection

The default physical machine is 4x2. The example selects the 16x8 reference.
Use a separate complete checkout for each physical machine or host compiler:
some libraries and device runtime products are shared within a checkout. Machine
and compiler selections are recorded under `build/kk6/`; subsequent phases read
them automatically and reject conflicting selections.

Host models and libraries default to `/usr/bin/clang` and `/usr/bin/clang++`
(Clang 21 on the validated AlmaLinux 9.8 system). Set both `HB_CC` and `HB_CXX`
to absolute executable paths on first setup to use another pair, for example
GCC Toolset 15. The customized RISC-V toolchain itself is built with system GCC;
its target compiler is independent of the compiler used for the simulator.

`HB_BUILD_JOBS=24` controls compilation concurrency, capped at `nproc`.
Each simulation uses `VERILATOR_THREADS=1`. Proc+Endpoint hierarchy is the default
for exec/profile/trace; debug remains flat. Explicit Make assignments can select
flat models for experiments (`VERILATOR_HIERARCHY=flat VERILATOR_THREADS=1`).

Resume individual phases:

```sh
bash setup-hammerblade.sh sources /path/to/checkout
bash setup-hammerblade.sh tools /path/to/checkout
bash setup-hammerblade.sh smoke /path/to/checkout
bash setup-hammerblade.sh profile /path/to/checkout
# Optional; large models can produce very large traces.
bash setup-hammerblade.sh trace /path/to/checkout
bash setup-hammerblade.sh debug /path/to/checkout
```

Provisioning rejects tracked source changes and changed submodule commits before
updating sources. Use a fresh checkout for a different release or experiments;
never run setup concurrently with another build writing that checkout. Setup
uses a checkout-local lock to serialize its own invocations.

## Run modes and validation

| Mode | DRAM library and output |
| --- | --- |
| exec | `libdramsim3_exec.so`; no DRAM statistics or BloodGraph |
| profile | `libdramsim3_profile.so`; ordinary statistics, no BloodGraph or instruction text |
| trace | `libdramsim3_trace.so`; statistics, BloodGraph bank-state trace, instruction text |
| debug | Same DRAM library as trace, plus FST waveforms |

All DRAM variants default to `-O2`, honor the host C++ compiler and have distinct
library identities. Building another mode preserves existing mode libraries.
BloodGraph is trace output and starts at initialization; runtime kernel-trace
controls do not gate it. Use separate run directories for all output files.

`validate-hammerblade.sh` runs Replicant vector addition in exec/profile, then
HammerBench vector addition on all tiles with 4096 elements, cold and warm.
It requires numerical PASS, core/cache counter rows, parsed statistics and the
profile DRAM output policy. The simpler Replicant kernel has no print-stat
markers; its header-only counters do not validate profiling.

To run from a configured checkout without changing your login environment:

```sh
bash run-hammerblade.sh /path/to/checkout \
  make -C bsg_replicant/examples/cuda/test_vec_add regression
```

The wrapper selects the recorded machine/compiler and local tools/libraries.
Explicit Make arguments remain available. Not all upstream application Makefiles
track changed flags, so use fresh outputs for compiler/flag experiments.

Build logs and `validation-record.json` are under `CHECKOUT/build/kk6/`. The
record captures source commits/dirty fingerprints, packages, selected compilers,
and hashes of tools, all built modes, libraries, device code and test outputs.
It describes what was tested and does not establish validity after changes.

## Validation scope

The source changes passed Linux tests with Clang 21 and GCC 15, and the clock
regression also passed GCC 11. All four complete physical-4x2 modes passed a
256-element vector addition with identical simulated marker times; exec/profile
were rerun after all modes were built to verify unchanged binaries and libraries.
The setup integration is checked separately using the commands above. macOS
compatibility is assumed at the project owner's request; these Linux checks do
not constitute a macOS build or run.
