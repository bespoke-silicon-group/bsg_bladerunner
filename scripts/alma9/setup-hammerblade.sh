#!/usr/bin/env bash
# Per-user, per-checkout setup. Install system prerequisites separately.
set -Eeuo pipefail
trap 'status=$?; printf "Setup stopped at line %s (exit %s). See the checkout build/kk6/logs directory.\n" "$LINENO" "$status" >&2; exit "$status"' ERR

usage() {
    printf '%s\n' \
        'Usage: bash setup-hammerblade.sh {all|sources|tools|smoke|profile|trace|debug} CHECKOUT' \
        'Run as an ordinary user. No sudo or system installation is performed.' \
        'Use scripts/alma9 in a committed Bladerunner checkout, or a release bundle.' \
        'A standalone bundle must include bladerunner-revision.txt and Python requirements.' \
        'Host builds default to Clang. HB_CC/HB_CXX select a different fresh-checkout pair.' \
        'HB_BUILD_JOBS defaults to 24 (capped at nproc).' \
        'HB_MACHINE_NAME defaults to pod_X1Y1_ruche_X4Y2_hbm_one_pseudo_channel.' \
        'Use a separate complete checkout for each machine configuration.'
}
if [[ "${1:-}" == --help || "${1:-}" == -h ]]; then usage; exit 0; fi
if (( $# != 2 || EUID == 0 )); then usage >&2; exit 2; fi
phase=$1
case "$phase" in all|sources|tools|smoke|profile|trace|debug) ;; *) usage >&2; exit 2 ;; esac
bundle_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
checkout=$(realpath -m -- "$2")
if [[ "$checkout" =~ [[:space:]] ]]; then
    printf 'The HammerBlade Makefiles require a checkout path without whitespace.\n' >&2
    exit 2
fi
if [[ -f "$bundle_dir/bladerunner-revision.txt" ]]; then
    bladerunner_revision=$(cat "$bundle_dir/bladerunner-revision.txt")
else
    bladerunner_revision=$(git -C "$bundle_dir" rev-parse HEAD)
fi
if [[ ! "$bladerunner_revision" =~ ^[0-9a-f]{40}$ ]]; then
    printf 'Missing exact Bladerunner revision. Use the complete release bundle.\n' >&2; exit 2
fi
toolchain_revision=656708846d723936eb5ba2648f6f919608a8ccaf
jobs=${HB_BUILD_JOBS:-24}
recorded_machine=pod_X1Y1_ruche_X4Y2_hbm_one_pseudo_channel
if [[ -f "$checkout/build/kk6/machine.txt" ]]; then
    recorded_machine=$(cat "$checkout/build/kk6/machine.txt")
fi
machine_name=${HB_MACHINE_NAME:-$recorded_machine}
if [[ ! "$jobs" =~ ^[1-9][0-9]*$ || ! "$machine_name" =~ ^[a-zA-Z0-9_]+$ ]]; then
    printf 'Invalid build-job count or machine name.\n' >&2; exit 2
fi
cpus=$(nproc)
(( jobs <= cpus )) || jobs=$cpus
toolchain="$checkout/bsg_manycore/software/riscv-tools/riscv-gnu-toolchain"

clone_at() {
    local url=$1 destination=$2 revision=$3
    if [[ ! -e "$destination" ]]; then
        mkdir -p -- "$(dirname -- "$destination")"
        git clone --no-checkout "$url" "$destination"
        git -C "$destination" checkout --detach "$revision"
    fi
    if [[ "$(git -C "$destination" rev-parse HEAD)" != "$revision" ]]; then
        printf 'Revision mismatch in %s. Choose a fresh checkout directory.\n' "$destination" >&2
        exit 1
    fi
}

if [[ "$phase" == all || "$phase" == sources ]]; then
    clone_at https://github.com/bespoke-silicon-group/bsg_bladerunner.git "$checkout" "$bladerunner_revision"
fi
cd -- "$checkout"
mkdir -p build/kk6/logs
exec 9>build/kk6/build.lock
flock -n 9 || { printf 'Another setup/build is using this checkout.\n' >&2; exit 1; }

if [[ "$phase" == all || "$phase" == sources ]]; then
    # Provisioning must never reset a user's modified source or submodule HEAD.
    if [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
        printf 'Source changes found. Use a fresh checkout for provisioning.\n' >&2; exit 1
    fi
    git -C "$checkout" -c url.https://github.com/.insteadOf=git@github.com: \
        submodule update --init --recursive --jobs 8 basejump_stl bsg_manycore bsg_replicant verilator
    clone_at https://github.com/bespoke-silicon-group/riscv-gnu-toolchain.git "$toolchain" "$toolchain_revision"
    git -C "$toolchain" submodule update --init --jobs 4 riscv-binutils riscv-gcc riscv-glibc riscv-newlib
fi

git rev-parse HEAD > build/kk6/bladerunner-revision.txt
git submodule status --recursive > build/kk6/bladerunner-submodules.txt
git -C "$toolchain" rev-parse HEAD > build/kk6/toolchain-revision.txt
git -C "$toolchain" submodule status > build/kk6/toolchain-submodules.txt
# Bind each build to its checkout; inherited project/compiler settings must not
# silently redirect generated code or runtime libraries to another experiment.
unset MAKEFLAGS MFLAGS CL_DIR BSG_F1_DIR BSG_MANYCORE_DIR BASEJUMP_STL_DIR
unset LLVM_DIR RISCV_LLVM_PATH RISCV_LLVM_OBJECT_OUTPUT CLANG
unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS CPATH LIBRARY_PATH PYTHONHOME
unset VERILATOR_HIERARCHY VERILATOR_PROFILE_HIERARCHY VERILATOR_THREADS
unset DRAMSIM3_OPT_FLAGS DRAMSIM3_CXXFLAGS DRAMSIM3_CPPFLAGS
export PATH="$checkout/build/kk6/python/bin:/usr/local/bin:/usr/bin:/bin"
export VERILATOR_ROOT="$checkout/verilator"
export VERILATOR="$VERILATOR_ROOT/bin/verilator"
export REPLICANT_PATH="$checkout/bsg_replicant"
export BSG_PLATFORM=bigblade-verilator
export BSG_MACHINE_PATH="$REPLICANT_PATH/machines/$machine_name"
export PYTHONPATH="$checkout/bsg_manycore/software/py"
export LD_LIBRARY_PATH="$REPLICANT_PATH/libraries/platforms/bigblade-verilator:$REPLICANT_PATH/libraries/features/dma/simulation:$REPLICANT_PATH/libraries/features/tracer/simulation:$REPLICANT_PATH/libraries/features/pc_histogram/simulation"
if [[ ! -f "$BSG_MACHINE_PATH/Makefile.machine.include" ]]; then
    printf 'Unknown machine: %s\n' "$machine_name" >&2; exit 1
fi
if [[ -f build/kk6/machine.txt && "$(cat build/kk6/machine.txt)" != "$machine_name" ]]; then
    printf 'This checkout has outputs for another machine. Use a fresh checkout.\n' >&2; exit 1
fi
printf '%s\n' "$machine_name" > build/kk6/machine.txt
if [[ "$phase" == sources ]]; then printf 'Pinned sources ready: %s\n' "$checkout"; exit 0; fi

host_cc=${HB_CC:-/usr/bin/clang}
host_cxx=${HB_CXX:-/usr/bin/clang++}
if [[ -f build/kk6/host-compilers.txt ]]; then
    mapfile -t compilers < build/kk6/host-compilers.txt
    if (( ${#compilers[@]} != 2 )); then printf 'Invalid compiler record.\n' >&2; exit 1; fi
    host_cc=${HB_CC:-${compilers[0]}}
    host_cxx=${HB_CXX:-${compilers[1]}}
    if [[ "$host_cc" != "${compilers[0]}" || "$host_cxx" != "${compilers[1]}" ]]; then
        printf 'This checkout is bound to another host compiler. Use a fresh checkout.\n' >&2; exit 1
    fi
fi
for compiler in "$host_cc" "$host_cxx"; do
    if [[ "$compiler" != /* || "$compiler" =~ [[:space:]] || ! -x "$compiler" ]]; then
        printf 'Expected an installed absolute compiler path: %s\n' "$compiler" >&2; exit 1
    fi
done
printf '%s\n' "$host_cc" "$host_cxx" > build/kk6/host-compilers.txt

run_logged() {
    local label=$1; shift
    printf 'Running %s; log: %s/build/kk6/logs/%s.log\n' "$label" "$checkout" "$label"
    if "$@" > "build/kk6/logs/$label.log" 2>&1; then return 0; else
        local result=$?
        tail -60 "build/kk6/logs/$label.log" >&2
        return "$result"
    fi
}
make_args=(-j"$jobs" CC="$host_cc" CXX="$host_cxx" SHELL=/bin/bash '.SHELLFLAGS=-e -o pipefail -c')
if [[ "$phase" == all || "$phase" == tools ]]; then
    python3 -m venv build/kk6/python
    run_logged python-install build/kk6/python/bin/python -m pip install --no-cache-dir -r "$bundle_dir/hammerblade-python-requirements.txt"
    run_logged verilator-build make "${make_args[@]}" verilator-exe
    # Sources are already pinned. This target does not fetch or reset them.
    run_logged riscv-gcc-build make -C bsg_manycore/software/riscv-tools build-riscv-gnu-tools \
        COMPILING_THREADS="$jobs" RISCV_INSTALL_DIR="$checkout/bsg_manycore/software/riscv-tools/riscv-install"
    run_logged parser-help python3 -m vanilla_parser --help
    "$VERILATOR" --version
    bsg_manycore/software/riscv-tools/riscv-install/bin/riscv32-unknown-elf-dramfs-gcc --version
fi
if [[ "$phase" == all || "$phase" == smoke || "$phase" == profile || "$phase" == trace || "$phase" == debug ]]; then
    target=sim-exec
    test_target=regression
    if [[ "$phase" == profile ]]; then target=sim-profile; test_target=profile.log; fi
    if [[ "$phase" == trace || "$phase" == debug ]]; then target=sim-$phase; test_target=$phase.log; fi
    run_logged "$target-build" make "${make_args[@]}" -f simulator.mk "$target" VERILATOR_THREADS=1
    # -W forces another simulation on repeat runs, but treats its input as
    # already made. Build the host library first for a fresh checkout.
    run_logged "$target-test-vec-add-host" make "${make_args[@]}" \
        -C bsg_replicant/examples/cuda/test_vec_add main.so VERILATOR_THREADS=1
    run_logged "$target-test-vec-add" make "${make_args[@]}" \
        -C bsg_replicant/examples/cuda/test_vec_add -W main.so "$test_target" VERILATOR_THREADS=1
    if [[ "$test_target" != regression ]]; then
        grep -q 'BSG REGRESSION TEST .*PASSED' "bsg_replicant/examples/cuda/test_vec_add/$test_target"
        # This simple kernel has no print-stat markers. The validation script
        # uses instrumented HammerBench kernels to test statistics parsing.
    fi
    printf 'PASS: vector addition on %s (%s).\n' "$machine_name" "$target"
fi
