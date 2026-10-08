#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
skill_installer="$repo_root/.chezmoiscripts/run_after_install_herdr_skill.sh"

bash -n "$skill_installer"
python3 - "$repo_root" <<'PY'
from __future__ import annotations

import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tomllib
from tempfile import TemporaryDirectory


repo = Path(sys.argv[1])
config = tomllib.loads((repo / "dot_config/herdr/config.toml").read_text())
assert config["worktrees"]["directory"] == "~/.herdr/worktrees"
assert config["session"]["resume_agents_on_restore"] is True
assert config["ui"]["agent_panel_sort"] == "priority"
assert config["ui"]["show_agent_labels_on_pane_borders"] is True
assert config["ui"]["toast"]["delivery"] == "herdr"
assert config["ui"]["sound"]["enabled"] is False
assert config["keys"]["prefix"] == "f12"

bashrc = (repo / "dot_bashrc").read_text()
match = re.search(r"(?ms)^codex\(\) \{(.*?)^\}", bashrc)
assert match, "Codex shell wrapper is missing"
wrapper = match.group(1)
assert "--yolo" not in wrapper, "codex resume must not gain permissions"
assert 'command codex --no-daemon "$@"' in wrapper

with TemporaryDirectory(prefix="codex-resume-wrapper-") as directory:
    root = Path(directory)
    bindir = root / "bin"
    bindir.mkdir()
    fake_codex = bindir / "codex"
    fake_codex.write_text(
        "#!/usr/bin/env bash\nprintf '%s\\n' \"$*\" >>\"$CODEX_CALLS\"\n"
    )
    fake_codex.chmod(0o755)
    calls = root / "calls.log"
    harness = root / "wrapper.sh"
    harness.write_text(
        f"codex() {{{wrapper}\n}}\n"
        "codex resume session-123\n"
        "codex resume session-456 --yolo\n"
        "codex mcp list\n"
        "codex\n"
    )
    env = os.environ.copy()
    env.update({"PATH": f"{bindir}:/usr/bin:/bin", "CODEX_CALLS": str(calls)})
    subprocess.run(["bash", str(harness)], env=env, check=True, capture_output=True)
    assert calls.read_text().splitlines() == [
        "--no-daemon resume session-123",
        "--no-daemon resume session-456 --yolo",
        "mcp list",
        "--no-daemon",
    ]

shared = (repo / "dot_config/agents/AGENTS.md").read_text()
assert "exactly one root implementation agent" in shared
assert "Delegate only when the user explicitly asks." in shared
assert "stage only task-owned paths" in shared
assert "Pushes, PRs, and deployments require separate explicit authority." in shared

skill = (repo / "dot_codex/skills/parallel-work/SKILL.md").read_text()
for expected in (
    "Interactive parallel", "Isolated autonomous", "Deliberation",
    "delegate", "agent-worker spawn", "agent-worker integrated",
    "sibling goals", "delegate recursively",
):
    assert expected.lower() in skill.lower(), expected

settings = json.loads((repo / "dot_pi/agent/settings.json.tmpl").read_text())
assert "~/.pi/agent/skills/herdr" in settings["skills"]
assert (repo / "dot_codex/skills/parallel-work/SKILL.md").is_file()
herdr_skill_installer = repo / ".chezmoiscripts/run_after_install_herdr_skill.sh"
installer_text = herdr_skill_installer.read_text()
assert "herdr --skill" in installer_text
assert ".codex/skills/herdr/SKILL.md" in installer_text
assert ".pi/agent/skills/herdr/SKILL.md" in installer_text

with TemporaryDirectory(prefix="herdr-config-check-") as directory:
    config_path = Path(directory) / "config.toml"
    config_path.write_text((repo / "dot_config/herdr/config.toml").read_text())
    if shutil.which("herdr"):
        env = os.environ.copy()
        env["HERDR_CONFIG_PATH"] = str(config_path)
        checked = subprocess.run(
            ["herdr", "config", "check"], env=env, text=True,
            capture_output=True, check=True,
        )
        assert "config: ok" in checked.stdout

with TemporaryDirectory(prefix="herdr-skill-install-") as directory:
    root = Path(directory)
    home = root / "home"
    bindir = root / "bin"
    bindir.mkdir()
    skill_source = root / "skill.md"
    skill_source.write_text("---\nname: herdr\ndescription: release 0.9.3\n---\n\nOfficial skill v0.9.3\n")
    fake_herdr = bindir / "herdr"
    fake_herdr.write_text(
        "#!/usr/bin/env bash\n"
        "[[ ${1:-} == --skill ]] || exit 2\n"
        "cat -- \"$HERDR_SKILL_SOURCE\"\n"
    )
    fake_herdr.chmod(0o755)
    env = os.environ.copy()
    env.update({
        "HOME": str(home),
        "PATH": f"{bindir}:/usr/bin:/bin",
        "HERDR_SKILL_SOURCE": str(skill_source),
    })
    installer = repo / ".chezmoiscripts/run_after_install_herdr_skill.sh"
    subprocess.run(["bash", str(installer)], env=env, check=True, capture_output=True)
    codex_skill = home / ".codex/skills/herdr/SKILL.md"
    pi_skill = home / ".pi/agent/skills/herdr/SKILL.md"
    expected = skill_source.read_text()
    assert codex_skill.read_text() == expected
    assert pi_skill.read_text() == expected
    skill_source.write_text("---\nname: herdr\ndescription: release 0.9.4\n---\n\nOfficial skill v0.9.4\n")
    subprocess.run(["bash", str(installer)], env=env, check=True, capture_output=True)
    assert codex_skill.read_text() == skill_source.read_text()
    assert pi_skill.read_text() == skill_source.read_text()

if shutil.which("herdr"):
    status = subprocess.run(["herdr", "integration", "status"], text=True, capture_output=True, check=True)
    assert "codex: current" in status.stdout
    assert "pi: current" in status.stdout
    effective = Path.home() / ".codex/hooks.json"
    if effective.is_file():
        hooks = json.loads(effective.read_text())
        assert "SessionStart" in hooks.get("hooks", {})
        assert "Stop" in hooks.get("hooks", {})
        hook_path = Path.home() / ".codex/herdr-agent-state.sh"
        assert hook_path.is_file()

    with TemporaryDirectory(prefix="herdr-codex-hook-merge-") as directory:
        root = Path(directory)
        home = root / "home"
        xdg = root / "xdg"
        home.mkdir()
        xdg.mkdir()
        template = (repo / "dot_codex/hooks.json.tmpl").read_text()
        rendered = subprocess.run(
            ["chezmoi", "--source", str(repo), "--override-data",
             json.dumps({"chezmoi": {"homeDir": str(home)}}), "execute-template"],
            input=template, text=True, capture_output=True, check=True,
        ).stdout
        hooks_path = home / ".codex/hooks.json"
        hooks_path.parent.mkdir(parents=True)
        hooks = json.loads(rendered)
        hooks["hooks"]["Notification"] = [{"hooks": [{"type": "command", "command": "custom-notification"}]}]
        hooks["userExtension"] = "preserve-me"
        hooks_path.write_text(json.dumps(hooks) + "\n")
        env = os.environ.copy()
        env.update({
            "HOME": str(home),
            "XDG_CONFIG_HOME": str(xdg),
            "HERDR_CONFIG_PATH": str(xdg / "herdr/config.toml"),
        })
        for _ in range(2):
            subprocess.run(
                ["herdr", "integration", "install", "codex"], env=env,
                text=True, capture_output=True, check=True,
            )
        merged = json.loads(hooks_path.read_text())
        assert merged["userExtension"] == "preserve-me"
        assert merged["hooks"]["Notification"][0]["hooks"][0]["command"] == "custom-notification"
        stop_commands = [
            hook.get("command", "")
            for group in merged["hooks"]["Stop"]
            for hook in group.get("hooks", [])
        ]
        assert any("agent-goal" in command and "hook-stop" in command for command in stop_commands)
        session_commands = [
            hook.get("command", "")
            for group in merged["hooks"]["SessionStart"]
            for hook in group.get("hooks", [])
        ]
        assert sum("herdr-agent-state.sh" in command for command in session_commands) == 1
        assert (home / ".codex/herdr-agent-state.sh").is_file()

print("Herdr workflow checks passed.")
PY
