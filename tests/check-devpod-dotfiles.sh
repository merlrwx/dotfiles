#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

bash -n "$repo_root/install.sh"
bash -n "$repo_root/assets/devpod/bashrc"

python3 - "$repo_root" <<'PY'
from pathlib import Path
from tempfile import TemporaryDirectory
import os
import subprocess
import sys

repo_root = Path(sys.argv[1])

with TemporaryDirectory(prefix="devpod-dotfiles-") as temp_dir:
    home = Path(temp_dir)
    fake_bin = home / "fake-bin"
    fake_bin.mkdir()
    bashrc = home / ".bashrc"
    bashrc.write_text("# Project DevContainer shell setup\nexport PROJECT_ENV=ready\n")
    (home / ".gitconfig").write_text('[credential]\n\thelper = devpod-forwarder\n')

    fake_curl = fake_bin / "curl"
    fake_curl.write_text(
        "#!/usr/bin/env bash\n"
        "set -euo pipefail\n"
        "case \"$*\" in\n"
        "  '-fsSL https://chatgpt.com/codex/install.sh')\n"
        "    printf 'installed\\n' >>\"$HOME/codex-installer-calls\"\n"
        "    cat <<'INSTALLER'\n"
        "#!/usr/bin/env bash\n"
        "set -euo pipefail\n"
        "install -d -m 0755 \"$CODEX_INSTALL_DIR\"\n"
        "cat >\"$CODEX_INSTALL_DIR/codex\" <<'CODEX'\n"
        "#!/usr/bin/env bash\n"
        "printf 'codex-test\\n'\n"
        "CODEX\n"
        "chmod 0755 \"$CODEX_INSTALL_DIR/codex\"\n"
        "INSTALLER\n"
        "    ;;\n"
        "  '-fsSL https://pi.dev/install.sh')\n"
        "    cat <<'INSTALLER'\n"
        "#!/usr/bin/env bash\n"
        "set -euo pipefail\n"
        "install -d -m 0755 \"$HOME/.pi/agent/bin\"\n"
        "cat >\"$HOME/.pi/agent/bin/pi\" <<'PI'\n"
        "#!/usr/bin/env bash\n"
        "printf 'pi-test\\n'\n"
        "PI\n"
        "chmod 0755 \"$HOME/.pi/agent/bin/pi\"\n"
        "INSTALLER\n"
        "    ;;\n"
        "  *) exit 9 ;;\n"
        "esac\n"
    )
    fake_curl.chmod(0o755)

    env = os.environ.copy()
    env["HOME"] = str(home)
    env["PATH"] = f"{fake_bin}:/usr/local/bin:/usr/bin:/bin"
    env["GIT_CONFIG_NOSYSTEM"] = "1"
    env.pop("GIT_CONFIG_GLOBAL", None)

    codex_config = home / ".codex/config.toml"
    for install_number in range(2):
        if install_number == 1:
            codex_config.write_text(
                codex_config.read_text()
                + '\n[projects."/workspace/project"]\ntrust_level = "trusted"\n'
            )
        subprocess.run(
            ["bash", str(repo_root / "install.sh")],
            env=env,
            text=True,
            capture_output=True,
            check=True,
        )

    bashrc_text = bashrc.read_text()
    assert "export PROJECT_ENV=ready" in bashrc_text
    assert '"$HOME/.local/bin:$PATH"' in (repo_root / "assets/devpod/bashrc").read_text()
    expected_source_line = (
        '[[ -r "$HOME/.config/merlrwx/devpod.bashrc" ]] '
        '&& source "$HOME/.config/merlrwx/devpod.bashrc"'
    )
    assert bashrc_text.count(expected_source_line) == 1

    include_paths = subprocess.run(
        ["git", "config", "--global", "--get-all", "include.path"],
        env=env,
        text=True,
        capture_output=True,
        check=True,
    ).stdout.splitlines()
    assert include_paths == [str(home / ".config/merlrwx/gitconfig")]
    safe_directories = subprocess.run(
        ["git", "config", "--get-all", "safe.directory"],
        env=env,
        text=True,
        capture_output=True,
        check=True,
    ).stdout.splitlines()
    assert safe_directories == ["/workspaces/*"]
    assert subprocess.run(
        ["git", "config", "--global", "credential.helper"],
        env=env,
        text=True,
        capture_output=True,
        check=True,
    ).stdout.strip() == "devpod-forwarder"

    shared_instructions = (repo_root / "dot_config/agents/AGENTS.md").read_text()
    assert (home / ".codex/AGENTS.md").read_text() == shared_instructions
    assert (home / ".pi/agent/AGENTS.md").read_text() == shared_instructions
    assert (home / ".codex/skills/autonomous-goal/SKILL.md").is_file()
    assert (home / ".config/starship.toml").is_file()
    assert (home / ".config/nvim/init.lua").is_file()
    assert (home / ".local/bin/codex").is_file()
    assert (home / "codex-installer-calls").read_text().splitlines() == ["installed"]
    assert codex_config.read_text().startswith('[tui]\ntheme = "gruvbox-material-hard"')
    assert 'trust_level = "trusted"' in codex_config.read_text()
    assert "mcp_servers" not in codex_config.read_text()
    assert (home / ".pi/agent/bin/pi").is_file()

    interactive_shell = subprocess.run(
        [
            "bash",
            "--noprofile",
            "--rcfile",
            str(bashrc),
            "-ic",
            "command -v pi && pi",
        ],
        env=env,
        text=True,
        capture_output=True,
        check=True,
    )
    assert str(home / ".pi/agent/bin/pi") in interactive_shell.stdout
    assert "pi-test" in interactive_shell.stdout

    # The workspace overlay copies no host tools or credentials.
    for absent in (
        ".config/mise/config.toml",
        ".config/herdr/config.toml",
        ".codex/auth.json",
        ".pi/agent/auth.json",
    ):
        assert not (home / absent).exists(), absent

with TemporaryDirectory(prefix="devpod-existing-codex-") as temp_dir:
    home = Path(temp_dir)
    fake_bin = home / "fake-bin"
    fake_bin.mkdir()
    existing_config = home / ".codex/config.toml"
    existing_config.parent.mkdir()
    existing_config.write_text('model = "workspace-choice"\n')
    existing_auth = home / ".codex/auth.json"
    existing_auth.write_text('{"fixture":"preserve"}\n')
    fake_codex = fake_bin / "codex"
    fake_codex.write_text("#!/usr/bin/env bash\nexit 0\n")
    fake_codex.chmod(0o755)
    fake_pi = fake_bin / "pi"
    fake_pi.write_text("#!/usr/bin/env bash\nexit 0\n")
    fake_pi.chmod(0o755)
    fake_curl = fake_bin / "curl"
    fake_curl.write_text("#!/usr/bin/env bash\nexit 8\n")
    fake_curl.chmod(0o755)
    env = os.environ.copy()
    env["HOME"] = str(home)
    env["PATH"] = f"{fake_bin}:/usr/local/bin:/usr/bin:/bin"
    env["GIT_CONFIG_NOSYSTEM"] = "1"
    subprocess.run(
        ["bash", str(repo_root / "install.sh")],
        env=env,
        text=True,
        capture_output=True,
        check=True,
    )
    assert existing_config.read_text() == 'model = "workspace-choice"\n'
    assert existing_auth.read_text() == '{"fixture":"preserve"}\n'
    assert not (home / "codex-installer-calls").exists()
PY

printf 'DevPod lightweight dotfiles checks passed.\n'
