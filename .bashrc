#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Use vi-style editing in the shell
set -o vi

# Clear screen with Ctrl+l
bind -x '"\C-l":clear'

# Basic editor/browser
export EDITOR=vim
export VISUAL=vim
export BROWSER=firefox

# Useful folders
export REPOS="$HOME/Repos"
export DOTFILES="$HOME/.dotfiles"

# Add local scripts/apps to PATH
export PATH="$HOME/.local/bin:$PATH"

# Bash history
export HISTFILE="$HOME/.bash_history"
export HISTSIZE=25000
export HISTFILESIZE=25000
export HISTCONTROL=ignoreboth

# Aliases
alias c='clear'
alias e='exit'
alias ..='cd ..'
alias repos='cd "$REPOS"'
alias dot='cd "$DOTFILES"'

alias ls='ls --color=auto'
alias ll='ls -la'
alias la='ls -lAh'

alias t='tmux'
alias gs='git status'
alias gp='git pull'
alias gl='git log --oneline --graph --decorate --all'

alias eb='vim ~/.bashrc'
alias sbr='source ~/.bashrc'

# SSH agent
#if [ -z "$SSH_AUTH_SOCK" ]; then
#    eval "$(ssh-agent -s)" >/dev/null
#fi

#ssh-add -l >/dev/null 2>&1 || ssh-add ~/.ssh/id_ed25519
