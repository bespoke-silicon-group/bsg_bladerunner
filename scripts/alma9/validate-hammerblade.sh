#!/usr/bin/env bash
# Correctness and statistics checks using an already configured checkout.
set -Eeuo pipefail
if (( $# != 1 )); then
    printf 'Usage: bash validate-hammerblade.sh CHECKOUT\n' >&2; exit 2
fi
bundle_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
checkout=$(cd -- "$1" && pwd -P)
jobs=${HB_BUILD_JOBS:-24}
if [[ ! "$jobs" =~ ^[1-9][0-9]*$ ]]; then
    printf 'Invalid build-job count.\n' >&2; exit 2
fi
cpus=$(nproc)
(( jobs <= cpus )) || jobs=$cpus
machine_name=$(cat "$checkout/build/kk6/machine.txt")
if [[ "$machine_name" =~ _ruche_X([0-9]+)Y([0-9]+)_hbm_ ]]; then
    tile_x=${BASH_REMATCH[1]}
    tile_y=${BASH_REMATCH[2]}
else
    printf 'Validation currently supports the named rectangular HBM machines.\n' >&2; exit 2
fi
export HB_MACHINE_NAME="$machine_name"
bash "$bundle_dir/setup-hammerblade.sh" smoke "$checkout"
bash "$bundle_dir/setup-hammerblade.sh" profile "$checkout"
exec 9>"$checkout/build/kk6/build.lock"
flock -n 9 || { printf 'Another build is using this checkout.\n' >&2; exit 1; }

runner=(bash "$bundle_dir/run-hammerblade.sh" "$checkout")
benchmark=bsg_replicant/examples/hb_hammerbench/apps/vector_add
"${runner[@]}" make -C "$benchmark" generate TILE_X="$tile_x" TILE_Y="$tile_y" VECTOR_SIZE=4096 \
    > "$checkout/build/kk6/logs/hammerbench-generate.log" 2>&1
for warm in no yes; do
    test_dir="$benchmark/tile-x_${tile_x}__tile-y_${tile_y}__vector-size_4096__warm-cache_${warm}"
    log="$checkout/build/kk6/logs/hammerbench-vector-add-$warm.log"
    printf 'Running HammerBench vector addition: %sx%s tiles, warm cache=%s\n' "$tile_x" "$tile_y" "$warm"
    if ! "${runner[@]}" make -j"$jobs" -C "$test_dir" main.so \
        SHELL=/bin/bash '.SHELLFLAGS=-e -o pipefail -c' > "$log" 2>&1; then
        tail -60 "$log" >&2; exit 1
    fi
    # Never confuse an earlier trace run's files with fresh profile output.
    if compgen -G "$checkout/$test_dir/blood_graph*" >/dev/null || [[ -e "$checkout/$test_dir/vanilla.log" ]]; then
        printf 'Trace files already exist in %s; use a fresh validation checkout.\n' "$test_dir" >&2; exit 1
    fi
    if ! "${runner[@]}" make -j"$jobs" -C "$test_dir" -W main.so \
        profile.log stats SHELL=/bin/bash '.SHELLFLAGS=-e -o pipefail -c' >> "$log" 2>&1; then
        tail -60 "$log" >&2; exit 1
    fi
    grep -q 'BSG REGRESSION TEST .*PASSED' "$checkout/$test_dir/profile.log"
    # A parser can exit successfully on a header-only CSV. Require actual data.
    for stats in vanilla_stats.csv vcache_stats.csv; do
        if (( $(wc -l < "$checkout/$test_dir/$stats") <= 1 )); then
            printf 'Missing profiling samples in %s/%s\n' "$test_dir" "$stats" >&2; exit 1
        fi
    done
    test -s "$checkout/$test_dir/stats/manycore_stats.log"
    test -s "$checkout/$test_dir/dramsim3.json"
    if compgen -G "$checkout/$test_dir/blood_graph*" >/dev/null || [[ -e "$checkout/$test_dir/vanilla.log" ]]; then
        printf 'Unexpected trace output from profile mode in %s.\n' "$test_dir" >&2; exit 1
    fi
done
python3 "$bundle_dir/record-hammerblade.py" "$checkout" "$machine_name"
printf 'PASS: execution, profiling, cold/warm HammerBench results, and statistics on %s.\n' "$machine_name"
