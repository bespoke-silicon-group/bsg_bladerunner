#!/usr/bin/env bash
# Shared system prerequisites for user-owned HammerBlade/Verilator checkouts.
# Run as an ordinary user; sudo is used only for DNF operations.
# This script has no storage provisioning or mounting operations.
set -Eeuo pipefail
trap 'status=$?; printf "Installation stopped at line %s (exit %s). Correct the error and rerun.\n" "$LINENO" "$status" >&2; exit "$status"' ERR

dry_run=false
case "${1:-}" in
    '') ;;
    --dry-run) dry_run=true ;;
    --help|-h)
        printf '%s\n' 'Usage: bash install-alma9-prerequisites.sh [--dry-run]' \
            'Enable AlmaLinux 9 CRB and install standard build dependencies.' \
            'Verilator, RISC-V tools, and Python environments belong to each checkout.' \
            'GitHub CLI authentication is handled separately by setup-github.sh.'
        exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 2 ;;
esac
if (( $# > 1 )); then
    printf 'Expected at most one argument.\n' >&2
    exit 2
fi

. /etc/os-release
if [[ "${ID:-}" != almalinux || "${VERSION_ID:-}" != 9.* ]]; then
    printf 'This installer requires AlmaLinux 9; found %s.\n' "${PRETTY_NAME:-unknown}" >&2
    exit 1
fi

# Explicit packages keep repeat runs idempotent and avoid broad development groups.
# CRB supplies texinfo (RISC-V tools); all other packages use AlmaLinux repos.
packages=(
    autoconf automake bc binutils bison bzip2 cmake curl diffutils
    dnf-plugins-core dtc expat-devel findutils flex gawk gcc gcc-c++
    gcc-toolset-15-binutils gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ git
    gmp-devel gperf gzip libmpc-devel libtool llvm-toolset lz4-devel m4 make mpfr-devel numactl
    patch perf perl pkgconf-pkg-config python3 python3-devel python3-pip
    tar texinfo time unzip wget which xz zlib-devel
)

printf '%s\n' 'Enable repository: crb' 'Install system packages:'
printf '  %s\n' "${packages[@]}"
if "$dry_run"; then
    exit 0
fi

admin=()
if (( EUID != 0 )); then
    admin=(sudo)
    sudo -v
fi
if ! rpm -q dnf-plugins-core >/dev/null 2>&1; then
    "${admin[@]}" dnf -y install dnf-plugins-core
fi
"${admin[@]}" dnf config-manager --set-enabled crb
"${admin[@]}" dnf -y install "${packages[@]}"

printf '\nInstalled package versions:\n'
rpm -q --qf '%{NAME}\t%{VERSION}-%{RELEASE}\t%{ARCH}\n' "${packages[@]}" | sort
printf '\nSUCCESS: AlmaLinux build prerequisites are ready. Return to the chat.\n'
