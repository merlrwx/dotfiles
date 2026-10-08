#!/usr/bin/env bash

set -euo pipefail

dotfiles_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
workspace_config="$HOME/.config/merlrwx"
workspace_bashrc="$workspace_config/devpod.bashrc"
workspace_gitconfig="$workspace_config/gitconfig"
codex_config="$HOME/.codex/config.toml"
source_line='[[ -r "$HOME/.config/merlrwx/devpod.bashrc" ]] && source "$HOME/.config/merlrwx/devpod.bashrc"'

install -Dm0644 "$dotfiles_root/assets/devpod/bashrc" "$workspace_bashrc"
install -Dm0644 "$dotfiles_root/assets/devpod/gitconfig" "$workspace_gitconfig"
install -Dm0644 "$dotfiles_root/dot_config/starship.toml" \
    "$HOME/.config/starship.toml"

while IFS= read -r -d '' config_file; do
    relative_path="${config_file#"$dotfiles_root/dot_config/nvim/"}"
    install -Dm0644 "$config_file" "$HOME/.config/nvim/$relative_path"
done < <(find "$dotfiles_root/dot_config/nvim" -type f -print0)

for agent_directory in "$HOME/.codex" "$HOME/.pi/agent"; do
    install -Dm0644 "$dotfiles_root/dot_config/agents/AGENTS.md" \
        "$agent_directory/AGENTS.md"
done

while IFS= read -r -d '' skill_file; do
    relative_path="${skill_file#"$dotfiles_root/dot_codex/skills/"}"
    install -Dm0644 "$skill_file" "$HOME/.codex/skills/$relative_path"
done < <(find "$dotfiles_root/dot_codex/skills" -type f -print0)

if [[ ! -e "$codex_config" ]]; then
    install -Dm0644 "$dotfiles_root/assets/devpod/codex-config.toml" "$codex_config"
fi

codex_install_dir="$HOME/.local/bin"
if ! command -v codex >/dev/null 2>&1 && [[ ! -x "$codex_install_dir/codex" ]]; then
    command -v curl >/dev/null 2>&1 || {
        printf 'curl is required to install Codex in this workspace.\n' >&2
        exit 1
    }
    export CODEX_INSTALL_DIR="$codex_install_dir"
    curl -fsSL https://chatgpt.com/codex/install.sh | sh
fi

pi_install_dir="$HOME/.local/bin"
if ! command -v pi >/dev/null 2>&1 && [[ ! -x "$pi_install_dir/pi" ]]; then
    command -v curl >/dev/null 2>&1 || {
        printf 'curl is required to install Pi in this workspace.\n' >&2
        exit 1
    }
    curl -fsSL https://pi.dev/install.sh | sh
fi

if [[ ! -f "$HOME/.bashrc" ]]; then
    install -Dm0644 /dev/null "$HOME/.bashrc"
fi
if ! grep -Fqx -- "$source_line" "$HOME/.bashrc"; then
    {
        [[ ! -s "$HOME/.bashrc" ]] || printf '\n'
        printf '# Lightweight personal shell settings for DevPod workspaces.\n%s\n' \
            "$source_line"
    } >>"$HOME/.bashrc"
fi

if ! git config --global --get-all include.path | grep -Fqx -- "$workspace_gitconfig"; then
    git config --global --add include.path "$workspace_gitconfig"
fi

printf 'Installed lightweight workspace dotfiles. Project tools remain in the project DevContainer.\n'
