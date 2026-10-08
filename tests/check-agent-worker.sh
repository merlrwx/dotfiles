#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$repo_root" <<'PY'
from __future__ import annotations

import json
import os
from pathlib import Path
import subprocess
import sys
from tempfile import TemporaryDirectory


source_root = Path(sys.argv[1])
worker_script = source_root / "dot_local/bin/executable_agent-worker"
goal_cli = source_root / "dot_local/bin/executable_agent-goal"


def run(argv: list[str], *, cwd: Path | None = None, env: dict[str, str] | None = None,
        check: bool = True) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(argv, cwd=cwd, env=env, text=True, capture_output=True)
    if check and result.returncode:
        raise AssertionError(f"command failed: {argv}\n{result.stdout}\n{result.stderr}")
    return result


def git(root: Path, *args: str) -> str:
    return run(["git", "-C", str(root), *args]).stdout.strip()


def contract(name: str, verify: str, owned: str) -> str:
    return f"""# Goal

## Outcome

Complete task {name}.

## Acceptance criteria

- Update {owned} to the task result.
- The task verifier passes.

## Scope

### May modify

- {owned}

### May operate

- Run the task verifier.

## Invariants

- Do not change sibling-owned files.

## Verification

Run `{verify}`.

## Git workflow

No commits, pushes, PRs, or deployments are authorized.
"""


with TemporaryDirectory(prefix="agent-worker-check-") as temporary:
    temp = Path(temporary)
    repo = temp / "project"
    repo.mkdir()
    run(["git", "init", "-q", str(repo)])
    git(repo, "config", "user.email", "worker-test@example.invalid")
    git(repo, "config", "user.name", "Agent Worker Test")
    (repo / "scripts").mkdir()
    (repo / "component-a.txt").write_text("baseline\n")
    (repo / "component-b.txt").write_text("baseline\n")
    (repo / "component-c.txt").write_text("baseline\n")
    verify_all = repo / "scripts/verify"
    verify_all.write_text(
        "#!/usr/bin/env bash\nset -euo pipefail\n"
        "[[ $(cat component-a.txt) == A ]]\n"
        "[[ $(cat component-b.txt) == B ]]\n"
        "[[ $(cat component-c.txt) == C ]]\n"
    )
    (repo / "scripts/verify-ab").write_text(
        "#!/usr/bin/env bash\nset -euo pipefail\n"
        "[[ $(cat component-a.txt) == A ]]\n"
        "[[ $(cat component-b.txt) == B ]]\n"
    )
    for name, value in (("a", "A"), ("b", "B"), ("c", "C")):
        (repo / f"scripts/verify-{name}").write_text(
            f"#!/usr/bin/env bash\nset -euo pipefail\n[[ $(cat component-{name}.txt) == {value} ]]\n"
        )
    for verifier in (repo / "scripts").iterdir():
        verifier.chmod(0o755)
    run(["git", "-C", str(repo), "add", "--all"])
    run(["git", "-C", str(repo), "commit", "-qm", "test: baseline"])
    base = git(repo, "rev-parse", "HEAD")

    goals = temp / "goals"
    goals.mkdir()
    for index, letter in enumerate(("a", "b", "c"), start=1):
        selected_verifier = ".agent/VERIFY" if letter == "c" else f"scripts/verify-{letter}"
        (goals / f"phase-0{index}.md").write_text(
            contract(f"phase-0{index}", selected_verifier, f"component-{letter}.txt")
        )
    custom_verifier = goals / "phase-03.verify"
    custom_verifier.write_text(
        "#!/usr/bin/env bash\nset -euo pipefail\n[[ $(cat component-c.txt) == C ]]\n"
    )
    custom_verifier.chmod(0o755)

    fake_bin = temp / "bin"
    fake_bin.mkdir()
    fake_state = temp / "herdr.json"
    fake_herdr = fake_bin / "herdr"
    fake_herdr.write_text("""#!/usr/bin/env python3
import json, os, subprocess, sys
from pathlib import Path

state_file = Path(os.environ['FAKE_HERDR_STATE'])
state = json.loads(state_file.read_text()) if state_file.exists() else {'agents': {}, 'workspaces': {}}
args = sys.argv[1:]
def option(name):
    return args[args.index(name) + 1]
if args[:2] == ['agent', 'list']:
    print(json.dumps({'result': {'agents': [{'name': name, 'state': item['state']} for name, item in state['agents'].items()]}}))
elif args[:2] == ['worktree', 'create']:
    repo = option('--cwd')
    branch = option('--branch')
    base = option('--base')
    path = option('--path')
    label = option('--label')
    subprocess.run(['git', '-C', repo, 'worktree', 'add', '-q', '-b', branch, path, base], check=True)
    workspace_id = f"test-w{len(state['workspaces']) + 1}"
    pane_id = f"{workspace_id}:p1"
    state['workspaces'][workspace_id] = {'repo': repo, 'path': path, 'name': label, 'pane': pane_id}
    state_file.write_text(json.dumps(state))
    print(json.dumps({'result': {'workspace': {'workspace_id': workspace_id}, 'root_pane': {'pane_id': pane_id}}}))
elif args[:2] == ['agent', 'start']:
    name = args[2]
    state['agents'][name] = {'state': 'idle', 'prompt': ''}
    state_file.write_text(json.dumps(state))
    print(json.dumps({'ok': True}))
elif args[:2] == ['agent', 'prompt']:
    name = args[2]
    state['agents'][name]['state'] = 'working'
    state['agents'][name]['prompt'] = args[3]
    state_file.write_text(json.dumps(state))
    print(json.dumps({'ok': True}))
elif args[:2] == ['agent', 'get']:
    print(json.dumps({'result': {'agent': state['agents'][args[2]]}}))
elif args[:2] == ['agent', 'read']:
    print('mock worker output')
elif args[:2] == ['worktree', 'remove']:
    workspace_id = option('--workspace')
    item = state['workspaces'][workspace_id]
    subprocess.run(['git', '-C', item['repo'], 'worktree', 'remove', item['path']], check=True)
    state_file.write_text(json.dumps(state))
    print(json.dumps({'ok': True}))
else:
    raise SystemExit(f"unexpected fake Herdr command: {args}")
""")
    fake_herdr.chmod(0o755)

    environment = os.environ.copy()
    environment.update({
        "PATH": f"{fake_bin}:/usr/bin:/bin",
        "HERDR_ENV": "1",
        "AGENT_RUNS_DIR": str(temp / "state/agent-runs"),
        "FAKE_HERDR_STATE": str(fake_state),
    })
    worktree_root = temp / "worktrees"

    def call_worker(*args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
        return run([sys.executable, str(worker_script), *args], env=environment, check=check)

    def spawn(name: str, goal: str, verifier: str, *extra: str) -> dict:
        output = call_worker(
            "spawn", "--repo", str(repo), "--run-id", "three-phase",
            "--name", name, "--goal", str(goals / goal), "--kind", "codex",
            "--base", git(repo, "rev-parse", "HEAD"), "--verify", verifier,
            "--worktree-root", str(worktree_root), *extra,
        ).stdout
        return json.loads(output)

    first = spawn("phase-01", "phase-01.md", "scripts/verify-a")
    second = spawn("phase-02", "phase-02.md", "scripts/verify-b")
    assert first["branch"] == "agent/phase-01"
    assert second["branch"] == "agent/phase-02"
    assert first["worktree"] != second["worktree"]
    assert first["workspace_id"] != second["workspace_id"]
    assert first["base_commit"] == second["base_commit"] == base
    for item, name in ((first, "phase-01"), (second, "phase-02")):
        worker_root = Path(item["worktree"])
        assert (worker_root / ".agent/ACTIVE").is_file()
        task_goal = (worker_root / ".agent/GOAL.md").read_text()
        assert f"Task: {name}" in task_goal
        assert "Do not discover or adopt sibling goals or tasks" in task_goal

    initial_agents = json.loads(fake_state.read_text())["agents"]
    assert set(initial_agents) == {"phase-01", "phase-02"}
    assert all(agent["state"] == "working" for agent in initial_agents.values())
    assert all("Do not push" in agent["prompt"] for agent in initial_agents.values())
    assert call_worker("status", "--run-id", "three-phase").returncode == 0

    worktree_count = len(git(repo, "worktree", "list", "--porcelain").splitlines())
    missing_verifier = call_worker(
        "spawn", "--repo", str(repo), "--run-id", "missing-verifier", "--name", "verify-missing",
        "--goal", str(goals / "phase-01.md"), "--verify", "scripts/missing",
        "--worktree-root", str(worktree_root), check=False,
    )
    assert missing_verifier.returncode != 0 and "Verifier is missing" in missing_verifier.stderr
    assert len(git(repo, "worktree", "list", "--porcelain").splitlines()) == worktree_count

    manifest_path = temp / "state/agent-runs/three-phase.json"
    manifest = json.loads(manifest_path.read_text())
    extra_active = temp / "reserved-worker/.agent"
    extra_active.mkdir(parents=True)
    (extra_active / "ACTIVE").write_text("reserved\n")
    manifest["tasks"]["reserved"] = {
        "name": "reserved", "worktree": str(extra_active.parent), "status": "launched"
    }
    manifest_path.write_text(json.dumps(manifest))
    capped = call_worker(
        "spawn", "--repo", str(repo), "--run-id", "three-phase", "--name", "phase-04",
        "--goal", str(goals / "phase-03.md"), "--verify", "scripts/verify-c",
        "--worktree-root", str(worktree_root), check=False,
    )
    assert capped.returncode != 0 and "three active" in capped.stderr
    manifest["tasks"].pop("reserved")
    manifest_path.write_text(json.dumps(manifest))

    assert call_worker(
        "spawn", "--repo", str(repo), "--run-id", "three-phase", "--name", "Bad-name",
        "--goal", str(goals / "phase-01.md"), "--worktree-root", str(worktree_root),
        check=False,
    ).returncode != 0
    assert call_worker(
        "spawn", "--repo", str(repo), "--run-id", "another-run", "--name", "phase-01",
        "--goal", str(goals / "phase-01.md"), "--worktree-root", str(worktree_root),
        check=False,
    ).returncode != 0
    assert call_worker("collect", "phase-01", "--run-id", "three-phase", check=False).returncode != 0

    first_root = Path(first["worktree"])
    second_root = Path(second["worktree"])
    (first_root / "component-a.txt").write_text("A\n")
    (first_root / "new-a.txt").write_text("new untracked A\n")
    (second_root / "component-b.txt").write_text("B\n")
    (second_root / "new-b.txt").write_text("new untracked B\n")
    run([str(goal_cli), "complete"], cwd=first_root)
    run([str(goal_cli), "complete"], cwd=second_root)
    verifier_a = first_root / "scripts/verify-a"
    verifier_contents = verifier_a.read_text()
    verifier_a.write_text("#!/usr/bin/env bash\nexit 0\n")
    tampered = call_worker("collect", "phase-01", "--run-id", "three-phase", check=False)
    assert tampered.returncode != 0 and "changed after activation" in tampered.stderr
    verifier_a.write_text(verifier_contents)
    collect_a = json.loads(call_worker("collect", "phase-01", "--run-id", "three-phase").stdout)
    collect_b = json.loads(call_worker("collect", "phase-02", "--run-id", "three-phase").stdout)
    patch_a = Path(collect_a["patch_path"]).read_text()
    patch_b = Path(collect_b["patch_path"]).read_text()
    assert "component-a.txt" in patch_a and "new-a.txt" in patch_a
    assert "component-b.txt" in patch_b and "new-b.txt" in patch_b

    blocked = call_worker(
        "spawn", "--repo", str(repo), "--run-id", "three-phase", "--name", "phase-03",
        "--goal", str(goals / "phase-03.md"), "--kind", "pi", "--base", base,
        "--verify", "scripts/verify-c", "--worktree-root", str(worktree_root),
        "--depends-on", "phase-01", check=False,
    )
    assert blocked.returncode != 0 and "not integrated" in blocked.stderr

    git(repo, "switch", "-c", "integration")
    for patch_path in (collect_a["patch_path"], collect_b["patch_path"]):
        run(["git", "-C", str(repo), "apply", "--3way", patch_path])
    run([str(repo / "scripts/verify-ab")], cwd=repo)
    run(["git", "-C", str(repo), "add", "--all"])
    run(["git", "-C", str(repo), "commit", "-qm", "feat: integrate phases one and two"])
    integration_base = git(repo, "rev-parse", "HEAD")
    failed_verify = call_worker(
        "integrated", "phase-01", "--run-id", "three-phase", "--at", integration_base,
        "--checkout", str(repo), "--verify", "scripts/verify", check=False,
    )
    assert failed_verify.returncode != 0
    assert json.loads(manifest_path.read_text())["tasks"]["phase-01"]["status"] == "prompt_submitted"
    for name in ("phase-01", "phase-02"):
        call_worker(
            "integrated", name, "--run-id", "three-phase", "--at", integration_base,
            "--checkout", str(repo), "--verify", "scripts/verify-ab",
        )

    third = spawn(
        "phase-03", "phase-03.md", str(custom_verifier), "--kind", "pi",
        "--depends-on", "phase-01", "--depends-on", "phase-02",
    )
    assert third["base_commit"] == integration_base
    third_root = Path(third["worktree"])
    assert (third_root / ".agent/VERIFY").is_file()
    assert json.loads((third_root / ".agent/ACTIVE").read_text())["verifier"] == ".agent/VERIFY"
    assert (third_root / "component-a.txt").read_text() == "A\n"
    assert (third_root / "component-b.txt").read_text() == "B\n"
    (third_root / "component-c.txt").write_text("C\n")
    run([str(goal_cli), "complete"], cwd=third_root)
    collect_c = json.loads(call_worker("collect", "phase-03", "--run-id", "three-phase").stdout)
    run(["git", "-C", str(repo), "apply", "--3way", collect_c["patch_path"]])
    run([str(repo / "scripts/verify")], cwd=repo)
    run(["git", "-C", str(repo), "add", "--all"])
    run(["git", "-C", str(repo), "commit", "-qm", "feat: integrate phase three"])
    call_worker(
        "integrated", "phase-03", "--run-id", "three-phase", "--at", "HEAD",
        "--checkout", str(repo), "--verify", "scripts/verify",
    )

    refusal = call_worker("cleanup", "phase-01", "--run-id", "three-phase", check=False)
    assert refusal.returncode != 0 and "dirty" in refusal.stderr
    manifest = json.loads((temp / "state/agent-runs/three-phase.json").read_text())
    assert [manifest["tasks"][name]["status"] for name in ("phase-01", "phase-02", "phase-03")] == [
        "integrated", "integrated", "integrated"
    ]
    assert len([item for item in git(repo, "worktree", "list", "--porcelain").splitlines() if item.startswith("worktree ")]) == 4

print("agent-worker checks passed.")
PY
