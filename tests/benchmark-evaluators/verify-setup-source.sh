#!/usr/bin/env bash

set -euo pipefail

repository=$PWD
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT
source_dir="$test_root/source with spaces"
mkdir -p "$source_dir"
cp "$repository/setup" "$source_dir/setup"
chmod +x "$source_dir/setup"

assert_apply_args() {
    local log=$1
    mapfile -t actual < "$log"
    if [[ ${actual[0]:-} == exec && ${actual[1]:-} == chezmoi && ${actual[2]:-} == -- && ${actual[3]:-} == chezmoi ]]; then
        actual=("${actual[@]:4}")
    elif [[ ${actual[0]:-} == exec && ${actual[1]:-} == -- && ${actual[2]:-} == chezmoi ]]; then
        actual=("${actual[@]:3}")
    fi

    case "${actual[*]}" in
        "init --apply --source $source_dir"|\
        "apply --source $source_dir"|\
        "--source $source_dir apply"|\
        "-S $source_dir apply") return 0 ;;
    esac
    printf 'unexpected chezmoi invocation:' >&2
    printf ' %q' "${actual[@]}" >&2
    printf '\n' >&2
    return 1
}

case_dir="$test_root/direct"
mkdir -p "$case_dir/bin"
printf '#!/bin/bash\nprintf "%%s\\n" "$@" > "$CALL_LOG"\n' > "$case_dir/bin/chezmoi"
printf '#!/bin/bash\nexit 91\n' > "$case_dir/bin/mise"
printf '#!/bin/bash\nexit 92\n' > "$case_dir/bin/curl"
ln -s /usr/bin/dirname "$case_dir/bin/dirname"
chmod +x "$case_dir/bin/chezmoi" "$case_dir/bin/mise" "$case_dir/bin/curl"
(cd "$source_dir" && CALL_LOG="$case_dir/call" PATH="$case_dir/bin" ./setup)
assert_apply_args "$case_dir/call"

case_dir="$test_root/mise"
mkdir -p "$case_dir/bin"
printf '#!/bin/bash\nif [[ ${1:-} == which ]]; then printf "%%s\\n" "$MANAGED_CHEZMOI"; exit 0; fi\nprintf "%%s\\n" "$@" > "$CALL_LOG"\n' > "$case_dir/bin/mise"
printf '#!/bin/bash\nprintf "%%s\\n" "$@" > "$CALL_LOG"\n' > "$case_dir/managed-chezmoi"
printf '#!/bin/bash\nexit 92\n' > "$case_dir/bin/curl"
ln -s /usr/bin/dirname "$case_dir/bin/dirname"
chmod +x "$case_dir/bin/mise" "$case_dir/bin/curl" "$case_dir/managed-chezmoi"
(cd "$source_dir" && CALL_LOG="$case_dir/call" MANAGED_CHEZMOI="$case_dir/managed-chezmoi" PATH="$case_dir/bin" ./setup)
assert_apply_args "$case_dir/call"

case_dir="$test_root/bootstrap"
mkdir -p "$case_dir/bin"
printf '#!/bin/bash\nprintf '\''printf "%%%%s\\\\n" "$@" > "$CALL_LOG"'\''\n' > "$case_dir/bin/curl"
printf '#!/bin/bash\nexec /bin/sh "$@"\n' > "$case_dir/bin/sh"
ln -s /usr/bin/dirname "$case_dir/bin/dirname"
chmod +x "$case_dir/bin/curl" "$case_dir/bin/sh"
(cd "$source_dir" && CALL_LOG="$case_dir/call" PATH="$case_dir/bin" ./setup)
assert_apply_args "$case_dir/call"
