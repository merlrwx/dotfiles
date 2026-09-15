# Fedora Sway Dotfiles

Portable configuration for Fedora Sway, Bash, Vim, tmux, Alacritty, Waybar,
Rofi, Starship, and mise. Chezmoi installs the configuration and the required
Fedora desktop packages.

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
- Screenshot helper and wallpaper
- Fedora packages required by the desktop configuration

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
