#!/usr/bin/env bash

set -euo pipefail

command -v herdr >/dev/null 2>&1 || exit 0

temporary="$(mktemp)"
trap 'rm -f -- "$temporary"' EXIT

herdr --skill >"$temporary"
if ! grep -Eq '^name: herdr$' "$temporary"; then
    printf 'Installed Herdr did not return its official herdr skill.\n' >&2
    exit 1
fi

for target in \
    "$HOME/.codex/skills/herdr/SKILL.md" \
    "$HOME/.pi/agent/skills/herdr/SKILL.md"; do
    mkdir -p -- "${target%/*}"
    if ! cmp -s -- "$temporary" "$target"; then
        install -m 0644 -- "$temporary" "$target"
    fi
done
