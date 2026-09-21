# Fedora Sway Dotfiles

Portable configuration for Fedora Sway, Bash, Vim, tmux, Alacritty, Waybar,
Rofi, Starship, mise, Herdr, and Codex. Chezmoi installs the configuration and
the required Fedora desktop packages.

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

## What is managed

- Sway configuration and portable key bindings
- Waybar configuration and styling
- Rofi configuration and Gruvbox theme
- Alacritty, Bash, Vim, tmux, Starship, and mise
- Herdr preferences and its Codex session integration
- Codex model preferences, MCP endpoints, portable project trust, and skills
- Screenshot helper and wallpaper
- Fedora packages required by the desktop configuration

Codex authentication, conversations, memories, databases, caches, generated
rules, and machine identity are deliberately not tracked. On a new machine,
run `codex` once and sign in after `chezmoi apply` finishes.

Codex loads the global Caveman skill on demand and automatically follows the
Conventional Commits skill whenever it creates or amends a Git commit.

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
