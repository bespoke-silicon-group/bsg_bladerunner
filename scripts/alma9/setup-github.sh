#!/usr/bin/env bash
# Install Git/GitHub CLI on AlmaLinux 9 and authenticate the invoking user.
# Run as your ordinary Unix user: bash setup-github.sh
# For server provisioning without personal login: bash setup-github.sh --packages-only
# Official instructions:
# https://github.com/cli/cli/blob/trunk/docs/install_linux.md#dnf4
# https://cli.github.com/manual/gh_auth_login
# https://cli.github.com/manual/gh_auth_setup-git

set -Eeuo pipefail

trap 'status=$?; printf "\nSetup stopped at line %s (exit %s). Fix the reported error and rerun this script.\n" "$LINENO" "$status" >&2; exit "$status"' ERR

packages_only=false
case "${1:-}" in
    '') ;;
    --packages-only) packages_only=true ;;
    --help|-h)
        printf '%s\n' \
            'Usage: bash setup-github.sh [--packages-only]' \
            'Installs system packages, then logs your Unix account into GitHub.' \
            'Use --packages-only to install prerequisites without personal login.' \
            'Run the default mode as your normal user, not with sudo.'
        exit 0
        ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 2 ;;
esac
if (( $# > 1 )); then
    printf 'Expected at most one argument. Use --help for usage.\n' >&2
    exit 2
fi

if [[ ! -r /etc/os-release ]]; then
    printf 'Cannot identify this operating system.\n' >&2
    exit 1
fi
. /etc/os-release
if [[ "${ID:-}" != almalinux || "${VERSION_ID:-}" != 9.* ]]; then
    printf 'This script supports AlmaLinux 9; found %s.\n' "${PRETTY_NAME:-unknown OS}" >&2
    exit 1
fi

if ! "$packages_only"; then
    if (( EUID == 0 )); then
        printf 'Run this script as your normal user (mbt on KK6), without sudo.\n' >&2
        printf 'It will request sudo only for system package installation.\n' >&2
        exit 1
    fi
    if [[ ! -t 0 || ! -t 1 ]]; then
        printf 'Run this script in an interactive terminal so GitHub can show its login code.\n' >&2
        exit 1
    fi
    if [[ -n "${GH_TOKEN:-}" || -n "${GITHUB_TOKEN:-}" ]]; then
        printf 'GH_TOKEN or GITHUB_TOKEN is set and would override the saved GitHub login.\n' >&2
        printf 'For this browser-login setup, unset those variables and rerun.\n' >&2
        exit 1
    fi
fi

admin=()
if (( EUID != 0 )); then
    admin=(sudo)
fi

printf '\n[1/3] Installing system tools in their normal locations.\n'
if ! rpm -q git dnf-plugins-core >/dev/null 2>&1; then
    "${admin[@]}" dnf -y install git 'dnf-command(config-manager)'
fi
if ! rpm -q gh >/dev/null 2>&1; then
    if [[ ! -e /etc/yum.repos.d/gh-cli.repo ]]; then
        "${admin[@]}" dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
    fi
    "${admin[@]}" dnf -y install gh
fi
git --version
gh --version

if "$packages_only"; then
    printf '\nSystem packages are ready. Personal GitHub authentication was skipped.\n'
    exit 0
fi

printf '\n[2/3] Connecting your Unix account to GitHub.\n'
if gh auth status --hostname github.com >/dev/null 2>&1; then
    printf 'Using your existing GitHub login.\n'
else
    printf '%s\n' \
        'GitHub will display a one-time code below.' \
        'On your phone or Mac, open https://github.com/login/device' \
        'Enter the displayed code and sign in as taylor-bsg (or another account with repository access).' \
        'Press Enter here if prompted to open a browser, then complete authorization on your phone or Mac.' \
        'Keep this terminal running until authorization completes.'
    # The browser is on the phone/Mac, so suppress a browser launch on KK6.
    GH_BROWSER=/usr/bin/true gh auth login --hostname github.com --git-protocol https --web
fi
gh auth setup-git --hostname github.com
github_login=$(gh api user --jq .login)
printf '\nAuthenticated GitHub account: %s\n' "$github_login"

printf '\n[3/3] Checking read access to bespoke-silicon-group/hb_handbook.\n'
if ! GIT_TERMINAL_PROMPT=0 git ls-remote --exit-code \
    https://github.com/bespoke-silicon-group/hb_handbook.git HEAD; then
    printf '\nRepository access failed for %s.\n' "$github_login" >&2
    printf 'Check the GitHub account and any required BSG organization authorization, then rerun.\n' >&2
    exit 1
fi

printf '\nSUCCESS: Git and GitHub CLI are ready, and hb_handbook is readable.\n'
printf 'No repository has been cloned or changed. You can now return to the chat.\n'
