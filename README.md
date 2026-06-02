# Terminal Dotfiles

Essential terminal configuration for bash, vim, tmux, and alacritty.

## Setup Instructions

Clone the repository and run the setup script:

```bash
DOTFILES_DIR=$HOME/Repos/github.com/CareSouth
mkdir -p $DOTFILES_DIR
cd $DOTFILES_DIR
git clone https://github.com/CareSouth/dotfiles.git
cd dotfiles
bash setup.sh
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
bash setup.sh
```

You can safely run it multiple times — it handles existing files gracefully.

## Customization

Edit the configuration files as needed:
- Bash: `.bashrc` and `.bash_profile`
- Vim: `.vimrc`
- Tmux: `.tmux.conf`
- Alacritty: `alacritty/alacritty.toml`

Changes take effect immediately for new terminal sessions.
