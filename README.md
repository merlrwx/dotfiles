# Fedora Sway and CLI Dotfiles

Portable configuration for a Fedora Sway desktop or a headless CLI host,
including Bash, Vim, tmux, Starship, mise, Herdr, and Codex. Chezmoi asks which
profile to use on first setup and installs Fedora desktop packages only for the
`fedora-sway` profile.

## Fresh Fedora setup

The quickest installation uses HTTPS, so it does not depend on SSH keys already
being available:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/merlrwx/dotfiles.git
```

Alternatively, clone the repository and run its bootstrap script:

```bash
PUBLIC_REPOS="$HOME/jd/20-29-code/repos/public"
mkdir -p "$PUBLIC_REPOS"
git clone https://github.com/merlrwx/dotfiles.git "$PUBLIC_REPOS/dotfiles"
cd "$PUBLIC_REPOS/dotfiles"
./setup
```

The first apply may ask for `sudo` so it can install the Fedora packages.

## Ubuntu and Amazon Linux 2023 CLI setup

Install Git and curl first so chezmoi can download and clone the source:

Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y curl git
```

Amazon Linux 2023:

```bash
sudo dnf install -y curl git
```

Then initialize the same repository and choose the `cli` profile when prompted:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/merlrwx/dotfiles.git
```

The CLI profile manages Bash, Vim, tmux, mise, Starship, Herdr, and Codex
configuration. It skips Sway, Waybar, Rofi, GTK, Thunar, Alacritty, wallpaper,
desktop entries, and Fedora desktop package/theme installation. The profile is
stored in the local chezmoi config, so later applies do not ask again.

## What is managed

- Sway configuration and portable key bindings (`fedora-sway` profile)
- Waybar configuration and styling
- Rofi configuration and Gruvbox theme
- Gruvbox GTK and icon themes, system dark mode, and JetBrains Mono UI font
- Thunar, its stable preferences and custom actions, and the directory file association
- Swaylock wallpaper configuration and Swayidle behavior
- Alacritty, Bash, Vim, tmux, Starship, and mise
- Herdr preferences and its Codex session integration
- Codex model preferences, MCP endpoints, portable project trust, and skills
- Screenshot helper and wallpaper
- Fedora packages required by the desktop configuration (`fedora-sway` profile)

Codex authentication, conversations, memories, databases, caches, generated
rules, and machine identity are deliberately not tracked. On a new machine,
run `codex` once and sign in after `chezmoi apply` finishes.

For authenticated homelab tools, follow [Homelab MCP with Codex](docs/homelab-mcp.md),
including laptop access over Tailscale and how to interpret HTTP 401 responses.

Codex loads the global Caveman skill on demand and automatically follows the
Conventional Commits skill whenever it creates or amends a Git commit. Chezmoi
also installs and enables the native `grill-me`, Ponytail, and `teach` plugins.
Restart Codex after the first apply so it discovers newly installed extensions.

Launching Herdr through the shell or desktop menu first updates the standalone
Codex and Herdr installs. If an update is unavailable, the launcher reports a
warning and opens the currently installed version.

Machine-specific output settings are deliberately not tracked. Put monitor and
workspace assignments in:

```text
~/.config/sway/config.d/10-desktop-outputs.conf
```

Discover a machine's output names with:

```bash
swaymsg -t get_outputs
```

Then add only that machine's layout to the local override. Chezmoi ignores the
file, so desktop monitor names cannot leak into the laptop configuration.

## Updating

Edit managed files normally, then capture and review the changes:

```bash
chezmoi re-add
chezmoi diff
chezmoi cd
git status
```

## Autonomous Codex goals

The Codex setup includes an opt-in autonomous goal loop built from a small
repository contract, fixed verification, and the native `Stop` hook. It supports
both reviewed goals produced after Grill Me and clear goals started immediately.

See [docs/autonomous-goals.md](docs/autonomous-goals.md) for setup, permissions,
Git workflows, interruption, recovery, and skill benchmarking.
