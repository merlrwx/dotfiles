# Terminal Dotfiles

Essential terminal configuration for bash, vim, tmux, and alacritty.

## Setup Instructions

Clone the repository and run the setup script:

```bash
PUBLIC_REPOS="$HOME/JD/20-29 Code/21 Public Repos"
mkdir -p "$PUBLIC_REPOS"
cd "$PUBLIC_REPOS"
git clone https://github.com/CareSouth/dotfiles.git
mv dotfiles "21.02 dotfiles"
cd "21.02 dotfiles"
./setup
```

## What's Included

- **Bash Configuration** (`.bashrc`, `.bash_profile`)
  - Vi-style editing
  - Common aliases for git, tmux, and file management
  - Environment variables and PATH setup
  - History configuration

- **Tmux Configuration** (`.tmux.conf`)
  - Mouse support
  - Vi-style copy mode
  - Custom status bar
  - Automatic window renaming
  - True color support

- **Vim Configuration** (`.vimrc`)
  - Line numbers and rulers
  - Search highlighting
  - Vi keybindings
  - 4-space indentation
  - Syntax highlighting

- **Alacritty Configuration** (`alacritty/alacritty.toml`)
  - JetBrains Mono font
  - Gruvbox dark theme
  - Tmux integration
  - Optimized padding and window decoration

## Usage

The setup script creates symlinks for all configurations. Run it to initialize your dotfiles:

```bash
./setup
```
