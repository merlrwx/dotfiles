#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readme="$repo_root/README.md"

for expected in \
    '### Isolated Codex workers (V2)' \
    'devpod up "$repo"' \
    'project=${repo##*/}' \
    'devpod ssh "$task" --workdir "/workspaces/$project"' \
    '--id "$task"' \
    'devpod ssh "$task"' \
    'git worktree add ".agent-worktrees/$task"' \
    'codex login --device-auth' \
    'homelab MCP' \
    ':/workspaces/${localWorkspaceFolderBasename}:Z' \
    'no scheduler'; do
    if ! grep -Fqi -- "$expected" "$readme"; then
        printf 'V2 worker documentation is missing: %s\n' "$expected" >&2
        exit 1
    fi
done

python3 <<'PY'
from pathlib import Path
from tempfile import TemporaryDirectory
import subprocess

with TemporaryDirectory(prefix="devpod-worker-worktrees-") as temp_dir:
    root = Path(temp_dir) / "project"
    root.mkdir()

    def git(*args: str) -> str:
        result = subprocess.run(
            ["git", "-C", str(root), *args],
            text=True,
            capture_output=True,
            check=True,
        )
        return result.stdout.strip()

    git("init", "-q")
    git("config", "user.name", "DevPod worker check")
    git("config", "user.email", "worker-check@example.invalid")
    (root / "source.txt").write_text("shared base\n")
    git("add", "source.txt")
    git("commit", "-qm", "test: seed workspace")
    git_dir = Path(git("rev-parse", "--git-common-dir"))
    if not git_dir.is_absolute():
        git_dir = root / git_dir
    exclude = git_dir / "info" / "exclude"
    exclude.parent.mkdir(parents=True, exist_ok=True)
    exclude.write_text("/.agent-worktrees/\n")

    first = root / ".agent-worktrees" / "task-a"
    second = root / ".agent-worktrees" / "task-b"
    git("worktree", "add", "-q", "-b", "agent/task-a", str(first), "HEAD")
    git("worktree", "add", "-q", "-b", "agent/task-b", str(second), "HEAD")
    (first / "source.txt").write_text("task a\n")

    assert (second / "source.txt").read_text() == "shared base\n"
    assert git("-C", str(first), "branch", "--show-current") == "agent/task-a"
    assert git("-C", str(second), "branch", "--show-current") == "agent/task-b"
    assert len([line for line in git("worktree", "list", "--porcelain").splitlines()
                if line.startswith("worktree ")]) == 3
    assert git("status", "--short") == ""
PY

printf 'DevPod isolated worker checks passed.\n'
