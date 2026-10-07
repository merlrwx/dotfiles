#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
external="$repo_root/.chezmoiexternals/neofetch.toml"
bashrc="$repo_root/dot_bashrc"
config="$repo_root/dot_config/neofetch/config.conf"
cat_logo="$repo_root/dot_config/neofetch/cat"
readme="$repo_root/README.md"

fail() {
    printf 'Neofetch startup check failed: %s\n' "$1" >&2
    exit 1
}

grep -Fq 'dylanaraps/neofetch/7.1.0/neofetch' "$external" || fail 'Neofetch source is not pinned to 7.1.0'
grep -Fq 'executable = true' "$external" || fail 'Neofetch external is not executable'
grep -Fq '3dc33493e54029fb1528251552093a9f9a2894fcf94f9c3a6f809136a42348c7' "$external" || fail 'Neofetch checksum is missing'

grep -Fq 'image_backend="ascii"' "$config" || fail 'ASCII backend is not enabled'
grep -Fq 'image_source="$HOME/.config/neofetch/cat"' "$config" || fail 'custom cat logo is not configured'
grep -Fq 'ascii_colors=(8 11)' "$config" || fail 'logo colors do not match Gruvbox Dark grey and amber'
grep -Fq '${c1}' "$cat_logo" || fail 'cat outline has no muted color marker'
grep -Fq '${c2}' "$cat_logo" || fail 'cat eyes have no accent color marker'
grep -Fq 'o' "$cat_logo" || fail 'cat eyes are missing'

grep -Fq 'command -v neofetch' "$bashrc" || fail 'startup does not check Neofetch availability'
grep -Fq '[[ -t 1 ]]' "$bashrc" || fail 'startup does not require terminal output'
grep -Fq 'tmux show-option -qv @dotfiles_neofetch_shown' "$bashrc" || fail 'tmux session guard is missing'
grep -Fq 'tmux set-option -q @dotfiles_neofetch_shown 1' "$bashrc" || fail 'tmux session guard is not recorded'
grep -Fq 'command -v clear >/dev/null 2>&1 && clear' "$bashrc" || fail 'startup screen is not cleared before Neofetch'
grep -Fq 'Neofetch with a colored cat logo' "$readme" || fail 'README does not document Neofetch startup'
bash -n "$bashrc" || fail 'Bash startup has invalid syntax'

printf 'Neofetch cat startup checks passed.\n'
