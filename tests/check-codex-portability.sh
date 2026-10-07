#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
installer="$repo_root/.chezmoiscripts/run_onchange_after_install_codex_extensions.sh.tmpl"
herdr_installer="$repo_root/.chezmoiscripts/run_onchange_after_configure_herdr_codex.sh.tmpl"
config="$repo_root/dot_codex/private_config.toml.tmpl"
externals="$repo_root/.chezmoiexternals/codex-skills.toml"
instructions="$repo_root/dot_codex/AGENTS.md"
theme="$repo_root/dot_codex/themes/gruvbox-material-hard.tmTheme"

assert_contains() {
    local file=$1
    local text=$2

    if ! grep -Fq -- "$text" "$file"; then
        printf 'FAIL: %s does not contain %s\n' "$file" "$text" >&2
        exit 1
    fi
}

assert_contains "$externals" '.codex/skills/caveman/SKILL.md'
assert_contains "$instructions" '## Teach workspaces'
assert_contains "$instructions" 'outside the Git worktree'
assert_contains "$instructions" 'even if ignored'
assert_contains "$config" '[tui]'
assert_contains "$config" 'theme = "gruvbox-material-hard"'
assert_contains "$theme" '<string>Gruvbox Material Hard</string>'
assert_contains "$herdr_installer" 'tail -c 1 "$hooks_file"'
for plugin in grill-me ponytail teach; do
    selector="engineering-suite-$plugin@openai-curated-remote"
    assert_contains "$installer" "$selector"
    assert_contains "$config" "[plugins.\"$selector\"]"
done

# Authentication and runtime state must remain local to each machine.
if find "$repo_root/dot_codex" -type f \
    \( -name 'auth.json' -o -name 'history.jsonl' -o -path '*/sessions/*' -o -path '*/cache/*' \) \
    -print -quit | grep -q .; then
    printf 'FAIL: runtime or authentication state is tracked under dot_codex\n' >&2
    exit 1
fi

printf 'Codex portability checks passed.\n'
