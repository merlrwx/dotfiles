#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
agent_goal="$repo_root/dot_local/bin/executable_agent-goal"
test_root="$(mktemp -d)"
trap 'rm -rf -- "$test_root"' EXIT

git -C "$test_root" init -q
git -C "$test_root" config user.email test@example.com
git -C "$test_root" config user.name Test
mkdir -p "$test_root/scripts" "$test_root/.agent"
printf '#!/usr/bin/env bash\nexit 0\n' > "$test_root/scripts/verify"
chmod +x "$test_root/scripts/verify"
printf 'baseline\n' > "$test_root/tracked.txt"
git -C "$test_root" add scripts/verify tracked.txt
git -C "$test_root" commit -qm 'test: baseline'
printf '# Goal\n\n## Outcome\n\nPass the verifier.\n' > "$test_root/.agent/GOAL.md"

(cd "$test_root" && "$agent_goal" start)
git -C "$test_root" check-ignore -q .agent/GOAL.md
(cd "$test_root" && "$agent_goal" status) | grep -q 'Status: active'

hook_output="$(printf '{"cwd":"%s","hook_event_name":"Stop","stop_hook_active":false}\n' "$test_root" | "$agent_goal" hook-stop)"
python3 -c 'import json,sys; assert json.load(sys.stdin)["decision"] == "block"' <<< "$hook_output"
hook_output="$(printf '{"cwd":"%s","hook_event_name":"Stop","stop_hook_active":true}\n' "$test_root" | "$agent_goal" hook-stop)"
python3 -c 'import json,sys; assert json.load(sys.stdin)["decision"] == "block"' <<< "$hook_output"

(cd "$test_root" && "$agent_goal" pause --force --reason test)
hook_output="$(printf '{"cwd":"%s","hook_event_name":"Stop","stop_hook_active":false}\n' "$test_root" | "$agent_goal" hook-stop)"
[[ "$hook_output" == '{}' ]]
(cd "$test_root" && "$agent_goal" resume)

printf '# changed\n' >> "$test_root/scripts/verify"
if (cd "$test_root" && "$agent_goal" complete >/dev/null 2>&1); then
    printf 'FAIL: changed verifier was accepted\n' >&2
    exit 1
fi
git -C "$test_root" restore scripts/verify
(cd "$test_root" && "$agent_goal" complete)
(cd "$test_root" && "$agent_goal" status) | grep -q 'Status: complete'
(cd "$test_root" && "$agent_goal" clear --force)

mkdir -p "$test_root/.agent"
printf '# Goal\n\n## Outcome\n\nExercise blocker handling.\n' > "$test_root/.agent/GOAL.md"
printf 'dirty\n' >> "$test_root/tracked.txt"
if (cd "$test_root" && "$agent_goal" start >/dev/null 2>&1); then
    printf 'FAIL: dirty worktree was accepted\n' >&2
    exit 1
fi
git -C "$test_root" restore tracked.txt
(cd "$test_root" && "$agent_goal" start)
(cd "$test_root" && "$agent_goal" block \
    --reason unavailable \
    --evidence checked \
    --attempted fallback \
    --unblock restore)
(cd "$test_root" && "$agent_goal" status) | grep -q 'Status: blocked'
hook_output="$(printf '{"cwd":"%s","hook_event_name":"Stop","stop_hook_active":true}\n' "$test_root" | "$agent_goal" hook-stop)"
[[ "$hook_output" == '{}' ]]
(cd "$test_root" && "$agent_goal" resume)
(cd "$test_root" && "$agent_goal" clear --force)

mkdir -p "$test_root/.agent"
printf '{invalid\n' > "$test_root/.agent/ACTIVE"
hook_output="$(printf '{"cwd":"%s","hook_event_name":"Stop","stop_hook_active":false}\n' "$test_root" | "$agent_goal" hook-stop)"
python3 -c 'import json,sys; assert "systemMessage" in json.load(sys.stdin)' <<< "$hook_output"
(cd "$test_root" && "$agent_goal" clear --force)

printf 'agent-goal checks passed.\n'
