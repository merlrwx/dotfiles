# Fedora Sway and CLI Dotfiles

Portable configuration for a Fedora Sway desktop and a headless CLI host.
Chezmoi manages the configuration and setup scripts; mise manages CLI tools and
the Node.js runtime. Both profiles get the shared shell, development tools,
Codex, Pi, Herdr, and DevPod. Homelab MCP is an optional capability; the
desktop profile adds GUI configuration.

## Install

Install Git and curl, then initialize chezmoi and select `fedora-sway` or `cli`:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/merlrwx/dotfiles.git
```

The first apply installs CLI prerequisites and the tools declared in mise.
Chezmoi's Pi setup script runs Pi's official installer inside mise's managed
Node.js environment. The desktop profile also installs Fedora desktop packages,
the IoskeleyMono font, and Gruvbox Material themes. The CLI profile uses no
host-name-specific role.

If starting from a clone, run `./setup` from the repository. On a new machine,
sign in to Codex and Pi separately after setup. The root `install.sh` is a
DevPod dotfiles callback; it installs a lightweight workspace setup and is not
the host setup command.

## Workflow modes

Use the same portable baseline on a laptop, at work, or on the home agentbox.
The host owns normal developer credentials. DevPod forwards supported Git,
SSH-agent, and Docker credentials to workspaces. Codex and Pi sign in separately
inside a workspace; host agent auth is never copied there. Regular project work
does not require homelab MCP.

```mermaid
flowchart LR
  subgraph host["Laptop or agentbox — portable host"]
    herdr["Herdr sessions"]
    credentials["Host credentials<br/>Git · SSH agent · Docker registry"]
    devpod["DevPod CLI"]
    checkout["Interactive host checkout"]
    hostagent["Codex or Pi<br/>host sign-in"]
    connect["Herdr pane:<br/>devpod ssh task"]
    herdr --> checkout --> hostagent
    herdr --> connect
    devpod --> connect
  end

  subgraph workspace["Optional isolated project workspace"]
    project["Project .devcontainer<br/>+ lightweight personal dotfiles"]
    worktree["One dedicated Git worktree<br/>per worker"]
    worker["Codex or Pi<br/>separate workspace sign-in"]
    project --> worktree --> worker
  end

  connect --> project
  credentials -.-> hostagent
  credentials -. "DevPod forwarding where supported" .-> project
  mcp["Optional homelab MCP\nfor homelab/API work"] -.-> hostagent
```

**Interactive mode:** run an agent on the host in Herdr. Use the host checkout
and its normal credentials; start DevPod only when the project's tools require
its DevContainer.

**Isolated worker mode (V2):** start one DevPod workspace with a unique ID per
task, create one Git worktree in that workspace, then run Codex or Pi there.
Start additional workers manually with their own workspace IDs and worktrees;
there is no scheduler. Choose one agent per worktree. Homelab MCP is available
only when separately configured and reachable; it is not needed for portable
Git or project work.

For the regular host flow, open a Herdr session and start Codex in its pane:

```bash
herdr --session codex
# In the Herdr pane:
codex
```

The Bash wrapper starts interactive Codex sessions without the shared
background daemon. This avoids feature-setting conflicts between CLI sessions
and other Codex clients; management commands such as `codex mcp` keep their
normal behavior.

Pi can use its own session too:

```bash
herdr --session pi
# In the Herdr pane:
pi
```

Both profiles include Git, SSH, curl, jq, mise, editors, terminal tools,
GitHub/GitLab CLIs, kubectl, Helm, Flux, Docker, DevPod, Codex, Pi, and Herdr.
Herdr manages host sessions and visibility. Repository DevContainer
instructions and `mise` tasks take precedence when available.

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

The workspace installer adds Codex and Pi, a small Bash overlay, Gruvbox
Material Starship and Neovim settings, Git defaults, shared agent instructions,
and a minimal Codex theme config. The Codex theme is seeded only when no user
config exists. The installer does not install the host `mise` tool set, Herdr,
Pi's host-only autonomous-goal extension, or homelab MCP configuration. It
never copies host agent auth or MCP files, Git, SSH, Docker, or provider
credentials. DevPod provides HTTPS Git credential helpers, SSH agent
forwarding, and Docker credential forwarding where supported. GitHub/GitLab API
CLI sign-ins and other provider credentials need their own supported auth flow;
they are not the Git credential helper.
See [DevPod dotfiles](https://devpod.sh/docs/developing-in-workspaces/dotfiles-in-a-workspace)
and [DevPod credential forwarding](https://devpod.sh/docs/developing-in-workspaces/credentials).

### Isolated Codex workers (V2)

This mode works with a normal DevPod provider, such as Docker on a laptop or
work machine. It does not require Tailscale or homelab MCP. Each worker has a
unique DevPod ID and a Git worktree inside that workspace's project checkout.
Create a fresh workspace for each task from the same repository:

```bash
repo=https://github.com/<owner>/<repo>
project=${repo##*/}
project=${project%.git}
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
devpod ssh "$task" --workdir "/workspaces/$project"
```

Inside the project directory in the workspace shell, create the task worktree
and start Codex there:

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

To try Pi in a worker, run `pi` from its task worktree and use `/login` on
first start. Pi and Codex have separate workspace sign-ins; choose one harness
per worktree. See the [Pi quickstart](https://pi.dev/docs/latest/quickstart).

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

## Shell, theme, and typography

The shared CLI palette is Gruvbox Material Dark Hard: it is reflected in the
Starship prompt, Bash syntax colors, Neovim, Yazi, tmux status bar, Alacritty,
and matching desktop UI themes. A fresh Codex config receives the matching
theme; existing Codex runtime configuration is preserved. Fedora Sway installs
and selects `IoskeleyMonoTerm Nerd Font Mono` for supported desktop
applications; remote terminal font rendering comes from the local terminal
client.

Bash uses ble.sh for interactive editing and completion, including syntax
highlighting, suggestions, and the navigable menu; Starship owns the prompt and
uses portable ASCII `>` and `git:<branch>` markers. Register native Bash
providers in `~/.config/bash/completions/init.sh` with
`command <tool> completion bash`; add wrappers there when runtime candidates are
missing.
At an idle prompt, Ctrl+C cancels the current line in both vi editing modes. The
`k` alias retains kubectl completion, Fabric pattern aliases are generated from
installed pattern names, and `yt` requests a video transcript. Neofetch shows a
colored cat once at interactive terminal startup (once per tmux session).
Tmux uses the matching status colors and enables terminal clipboard forwarding
where the client supports it; detach with the usual `Ctrl-b`, then `d`.

## Plan a complex change

Discuss and research the idea in ChatGPT, save a draft `PLAN.md` in the
repository, then use `$grill-me` to find missing decisions and sharpen its
acceptance criteria in a Pi session. Keep that planning work separate. Start a
fresh Codex session to implement the revised plan.

See [the example plan](docs/PLAN-example.md) and
[the autonomous goal workflow](docs/autonomous-goals.md).

## Optional homelab MCP

On the home network, Codex and host-installed Pi can use the homelab MCP endpoint
for privileged homelab/API work. Each agent has a separate OAuth login and
stores its own credentials locally. The lightweight DevPod installer does not
copy MCP settings or auth, and ordinary Git/project work does not depend on this
service. Follow [Homelab MCP setup](docs/homelab-mcp.md) after connecting to the
homelab network.
