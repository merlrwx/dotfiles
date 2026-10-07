# Fedora Sway and CLI Dotfiles

Portable configuration for two profiles: a Fedora Sway desktop and a headless
CLI host. Both receive the same shell, development tools, Codex, Pi, Herdr,
DevPod, shared instructions, and homelab MCP endpoint. The desktop profile adds
GUI configuration.

## Install

Install Git and curl, then initialize chezmoi and select `fedora-sway` or `cli`:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/merlrwx/dotfiles.git
```

The first apply installs CLI prerequisites and the tools declared in mise. The
desktop profile also installs Fedora desktop packages and Gruvbox Material
themes. The CLI profile uses no host-name-specific role.

If starting from a clone, run `./setup` from the repository. On a new machine,
sign in to Codex and Pi separately after setup. Credentials are local and are
never copied between the agents.

## Daily use

Run each harness on the host in its own Herdr session. For example, open a
session and start the harness in its pane:

```bash
herdr --session codex
# In the Herdr pane:
codex
```

For Pi, start a separate session:

```bash
herdr --session pi
# In the Herdr pane:
pi
```

Both profiles include Git, SSH, curl, jq, mise, editors, terminal tools,
GitHub/GitLab CLIs, kubectl, Helm, Flux, Docker, DevPod, Codex, Pi, and Herdr.
Herdr manages sessions and visibility. DevPod/DevContainer is optional project
tooling used from those sessions; it does not host the agents. When working in
parallel, start each agent manually in its own Git worktree. V0 has no automatic
worker spawning or scheduler. Repository-specific DevPod/DevContainer
instructions and `mise` tasks take precedence when available.

The shell uses ble.sh for interactive editing and completion. Neofetch shows a
colored cat once at interactive terminal startup.

## Plan a complex change

Discuss and research the idea in ChatGPT, save a draft `PLAN.md` in the
repository, then use `$grill-me` to find missing decisions and sharpen its
acceptance criteria in a Pi session. Keep that planning work separate. Start a
fresh Codex session to implement the revised plan.

See [the example plan](docs/PLAN-example.md) and
[the autonomous goal workflow](docs/autonomous-goals.md).

## Themes and shell

The shared shell, editors, and CLI use Gruvbox Material dark hard. Fedora Sway
adds matching Alacritty, Waybar, Rofi, and GTK themes. Bash uses ble.sh for
syntax highlighting, suggestions, and menu completion; Starship owns the
prompt.

## Homelab MCP

Codex and Pi use the same homelab endpoint. Each agent has a separate OAuth
login and stores its own credentials locally. Follow
[Homelab MCP setup](docs/homelab-mcp.md) after connecting to the homelab network.
