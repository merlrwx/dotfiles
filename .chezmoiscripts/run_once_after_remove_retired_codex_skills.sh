#!/usr/bin/env bash

set -euo pipefail

skills_dir="$HOME/.codex/skills"
rm -f -- \
    "$skills_dir/caveman/SKILL.md" \
    "$skills_dir/conventional-commits/SKILL.md" \
    "$skills_dir/conventional-commits/agents/openai.yaml"
rmdir --ignore-fail-on-non-empty \
    "$skills_dir/caveman" \
    "$skills_dir/conventional-commits/agents" \
    "$skills_dir/conventional-commits" 2>/dev/null || true
