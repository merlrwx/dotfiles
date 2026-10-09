#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf -- "$test_root"' EXIT

run_shell() {
    local home=$1
    (cd "$test_root" && env HOME="$home" PATH=/usr/bin:/bin \
        SSH_AUTH_SOCK=/dev/null TERM=dumb PS1= PROMPT_COMMAND=: \
        bash --noprofile --rcfile "$repo_root/dot_bashrc" -ic 'alias' 2>/dev/null || true)
}

empty_home="$test_root/empty-home"
mkdir -p "$empty_home/.config/fabric/patterns"
empty_output="$(run_shell "$empty_home")"
if grep -Fq "alias '*'" <<<"$empty_output"; then
    printf 'FAIL: an empty Fabric patterns directory created a wildcard alias.\n' >&2
    exit 1
fi

pattern_home="$test_root/pattern-home"
patterns="$pattern_home/.config/fabric/patterns"
mkdir -p "$patterns"
: >"$patterns/summarize"
: >"$patterns/unsafe name"
: >"$patterns/bad\$(touch hacked)"

output="$(run_shell "$pattern_home")"
if ! grep -Fxq "alias summarize='fabric --pattern summarize'" <<<"$output"; then
    printf 'FAIL: the normal Fabric pattern alias was not created.\n' >&2
    exit 1
fi
if grep -Fq 'unsafe name' <<<"$output"; then
    printf 'FAIL: an invalid Fabric alias name was created.\n' >&2
    exit 1
fi
if [[ -e "$test_root/hacked" ]]; then
    printf 'FAIL: a Fabric pattern filename ran shell code during startup.\n' >&2
    exit 1
fi

printf 'Fabric alias checks passed.\n'
