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
Herdr manages host sessions and visibility. The normal interactive mode runs
Codex on the host and uses DevPod for project tools. The optional V2 worker mode
runs Codex inside a separate DevPod workspace. Start workers manually; there
is no scheduler. Every worker must own a separate Git worktree. Repository
DevContainer instructions and `mise` tasks take precedence when available.

### Lightweight DevPod dotfiles

DevPod can install the personal shell, editor, Git defaults, and shared agent
instructions without applying the full host CLI profile. The project continues
to provide its language and platform tools through `.devcontainer`.

For one workspace, add the dotfiles repository when creating it:

```bash
devpod up <project-or-workspace> \
  --dotfiles https://github.com/merlrwx/dotfiles.git \
  --dotfiles-script install.sh
```

To use this for all new workspaces in the selected DevPod context:

```bash
devpod context set-options \
  -o DOTFILES_URL=https://github.com/merlrwx/dotfiles.git \
  -o DOTFILES_SCRIPT=install.sh
```

The workspace installer adds Codex, a small Bash overlay, Gruvbox Material
Starship and Neovim settings, Git defaults, shared agent instructions, and a
minimal Codex theme config. It does not install the host `mise` tool set,
Herdr, or homelab MCP configuration. It never copies host Codex auth, Git,
SSH, Docker, or provider credentials. DevPod provides HTTPS Git credential
helpers, SSH agent forwarding, and Docker credential forwarding where
supported. GitHub/GitLab API CLI sign-ins and other provider credentials need
their own supported auth flow; they are not the Git credential helper.
See [DevPod dotfiles](https://devpod.sh/docs/developing-in-workspaces/dotfiles-in-a-workspace)
and [DevPod credential forwarding](https://devpod.sh/docs/developing-in-workspaces/credentials).

### Isolated Codex workers (V2)

This mode works with a normal DevPod provider, such as Docker on a laptop or
work machine. It does not require Tailscale or homelab MCP. Each worker has a
unique DevPod ID and a Git worktree inside that workspace's project checkout.
Create a fresh workspace for each task from the same repository:

```bash
repo=https://github.com/<owner>/<repo>
task=api-timeouts

devpod up "$repo" \
  --id "$task" \
  --ide none \
  --dotfiles https://github.com/merlrwx/dotfiles.git \
  --dotfiles-script install.sh
```

Start a named Herdr session on the host and connect it to that worker:

```bash
herdr --session "codex-$task"
# In the Herdr pane:
devpod ssh "$task"
```

Inside the workspace shell, create the task worktree and start Codex there:

```bash
task=api-timeouts
git fetch origin
mkdir -p .agent-worktrees
grep -Fxq '/.agent-worktrees/' .git/info/exclude || \
  printf '/.agent-worktrees/\n' >> .git/info/exclude
git worktree add ".agent-worktrees/$task" -b "agent/$task" HEAD
cd ".agent-worktrees/$task"
codex
```

Repeat with a new task name and DevPod ID for every additional worker. The
worktree is inside its workspace so the project checkout, worktree, and
DevContainer tools stay together. Codex can push branches through DevPod's
Git credential helper or forwarded SSH agent. DevPod also supports Docker
registry credential forwarding. Codex itself uses a separate workspace sign-in;
on first use run `codex login --device-auth` and finish the device flow. Its
auth stays in that workspace and is never copied from the host. See the
[Codex CLI install guide](https://learn.chatgpt.com/docs/codex/cli) and
[login reference](https://learn.chatgpt.com/docs/developer-commands).

GitHub/GitLab API CLIs and cloud CLIs have their own authentication. If a task
needs them, install the required CLI in that project's DevContainer and use its
normal sign-in flow. Ordinary Git fetch, commit, and push remain independent
of those APIs and of homelab MCP. Herdr sees the DevPod SSH command rather than
the Codex process, so its worker-state indicator may be limited across that
SSH hop.

On a Fedora or other SELinux-enforcing Linux host, a workspace can fail with
`Permission denied` under `/workspaces` even when file ownership looks correct.
DevPod's Linux guidance is to relabel the project mount in that project's
`.devcontainer/devcontainer.json`:

```json
{
  "workspaceMount": "",
  "workspaceFolder": "/workspaces/${localWorkspaceFolderBasename}",
  "runArgs": [
    "--volume=${localWorkspaceFolder}:/workspaces/${localWorkspaceFolderBasename}:Z"
  ]
}
```

Merge these values with the project's existing DevContainer settings. Use this
SELinux-specific mount only on enforcing Linux hosts; other hosts should keep
their normal workspace mount. See [DevPod Linux troubleshooting](https://devpod.sh/docs/troubleshooting/linux-troubleshooting).

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
