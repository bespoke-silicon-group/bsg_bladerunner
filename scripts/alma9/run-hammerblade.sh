#!/usr/bin/env bash
# Run one command using a configured checkout, without changing the login shell.
set -Eeuo pipefail
if (( $# < 2 )); then
    printf 'Usage: bash run-hammerblade.sh CHECKOUT COMMAND [ARGUMENT ...]\n' >&2
    exit 2
fi
checkout=$(cd -- "$1" && pwd -P)
shift
machine_name=$(cat "$checkout/build/kk6/machine.txt")
if [[ ! "$machine_name" =~ ^[a-zA-Z0-9_]+$ ]]; then
    printf 'Invalid recorded machine name.\n' >&2; exit 1
fi
unset CL_DIR BSG_F1_DIR BSG_MANYCORE_DIR BASEJUMP_STL_DIR
unset LLVM_DIR RISCV_LLVM_PATH RISCV_LLVM_OBJECT_OUTPUT CLANG
unset MAKEFLAGS MFLAGS CFLAGS CXXFLAGS CPPFLAGS LDFLAGS CPATH LIBRARY_PATH PYTHONHOME
unset VERILATOR_HIERARCHY VERILATOR_PROFILE_HIERARCHY
unset DRAMSIM3_OPT_FLAGS DRAMSIM3_CXXFLAGS DRAMSIM3_CPPFLAGS
export REPLICANT_PATH="$checkout/bsg_replicant"
export BSG_MACHINE_PATH="$REPLICANT_PATH/machines/$machine_name"
export BSG_PLATFORM=bigblade-verilator
export VERILATOR_ROOT="$checkout/verilator"
export VERILATOR="$VERILATOR_ROOT/bin/verilator"
export VERILATOR_THREADS=1
mapfile -t compilers < "$checkout/build/kk6/host-compilers.txt"
if (( ${#compilers[@]} != 2 )) || [[ ! -x "${compilers[0]}" || ! -x "${compilers[1]}" ]]; then
    printf 'Missing or invalid host compiler record. Run setup first.\n' >&2; exit 1
fi
export CC="${compilers[0]}" CXX="${compilers[1]}"
export PATH="$checkout/build/kk6/python/bin:$checkout/bsg_manycore/software/riscv-tools/riscv-install/bin:/usr/local/bin:/usr/bin:/bin"
export PYTHONPATH="$checkout/bsg_manycore/software/py"
export LD_LIBRARY_PATH="$REPLICANT_PATH/libraries/platforms/bigblade-verilator:$REPLICANT_PATH/libraries/features/dma/simulation:$REPLICANT_PATH/libraries/features/tracer/simulation:$REPLICANT_PATH/libraries/features/pc_histogram/simulation"
cd -- "$checkout"
exec "$@"
