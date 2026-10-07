#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

managed_for() {
    chezmoi --source "$repo_root" \
        --override-data "{\"profile\":\"$1\"}" \
        managed
}

cli_managed="$(managed_for cli)"
desktop_managed="$(managed_for fedora-sway)"

shared_paths=(
    .bashrc
    .bash_profile
    .tmux.conf
    .vimrc
    .config/mise/config.toml
    .config/starship.toml
    .config/nvim/init.lua
    .config/nvim/lua/config/clipboard.lua
    .config/nvim/lua/config/lazy.lua
    .config/nvim/lua/config/options.lua
    .config/nvim/lua/plugins/gruvbox_material.lua
    .config/yazi/theme.toml
    .config/yazi/yazi.toml
    .config/yazi/flavors/gruvbox-material.yazi/flavor.toml
    .codex/config.toml
)

desktop_paths=(
    .config/Thunar/uca.xml
    .config/alacritty/alacritty.toml
    .config/gtk-3.0/settings.ini
    .config/gtk-4.0/settings.ini
    .config/mimeapps.list
    .config/rofi/config.rasi
    .config/sway/config
    .config/swaylock/config
    .config/waybar/config.jsonc
    .config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml
    .local/bin/sway-snip
    .local/share/applications/herdr.desktop
    .local/share/fonts/JetBrainsMonoNerdFont/JetBrainsMonoNerdFont-Regular.ttf
    .local/share/fonts/JetBrainsMonoNerdFont/JetBrainsMonoNerdFont-Bold.ttf
    .local/share/fonts/JetBrainsMonoNerdFont/JetBrainsMonoNerdFont-Italic.ttf
    .local/share/fonts/JetBrainsMonoNerdFont/JetBrainsMonoNerdFont-BoldItalic.ttf
    Pictures/wallpaper.jpg
    .chezmoiscripts/install_fedora_sway_packages.sh
    .chezmoiscripts/zz_install_gruvbox_desktop.sh
)

for path in "${shared_paths[@]}"; do
    if ! grep -Fxq "$path" <<<"$cli_managed"; then
        printf 'CLI profile is missing shared path: %s\n' "$path" >&2
        exit 1
    fi
done

for path in "${desktop_paths[@]}"; do
    if grep -Fxq "$path" <<<"$cli_managed"; then
        printf 'CLI profile unexpectedly manages desktop path: %s\n' "$path" >&2
        exit 1
    fi
    if ! grep -Fxq "$path" <<<"$desktop_managed"; then
        printf 'Fedora Sway profile is missing desktop path: %s\n' "$path" >&2
        exit 1
    fi
done

alacritty_font="$repo_root/dot_config/alacritty/alacritty.toml"
nerd_font_families="$(grep -Fc 'family = "JetBrainsMono Nerd Font"' "$alacritty_font")"
if [[ "$nerd_font_families" -ne 4 ]]; then
    printf 'Alacritty should use JetBrainsMono Nerd Font for all four styles.\n' >&2
    exit 1
fi

font_external="$repo_root/.chezmoiexternals/jetbrains-mono-nerd-font.toml"
for expected in \
    'JetBrainsMono.tar.xz' \
    '04d5e8f903693f9dd13e16f867e994834e681eb3c72c0d337a770dcda09010cf' \
    'fedora-sway'; do
    if ! grep -Fq "$expected" "$font_external"; then
        printf 'Nerd Font external is missing expected configuration: %s\n' "$expected" >&2
        exit 1
    fi
done

fedora_packages="$repo_root/.chezmoiscripts/run_onchange_after_install_fedora_sway_packages.sh.tmpl"
theme_script="$repo_root/.chezmoiscripts/run_onchange_after_zz_install_gruvbox_desktop.sh.tmpl"
for script in "$fedora_packages" "$theme_script"; do
    if ! grep -Fq '!= "fedora-sway"' "$script"; then
        printf 'Desktop provisioning is not profile-gated: %s\n' "$script" >&2
        exit 1
    fi

    rendered_script="$(chezmoi --source "$repo_root" \
        --override-data '{"profile":"cli"}' execute-template <"$script")"
    if [[ "$rendered_script" != '#!/usr/bin/env bash'* ]]; then
        printf 'Rendered provisioning script has no leading Bash shebang: %s\n' "$script" >&2
        exit 1
    fi
    if ! bash -n <<<"$rendered_script"; then
        printf 'Rendered provisioning script has invalid Bash syntax: %s\n' "$script" >&2
        exit 1
    fi
done

config_template="$repo_root/.chezmoi.toml.tmpl"
if ! grep -Fq '"fedora-sway"' "$config_template" || ! grep -Fq '"cli"' "$config_template"; then
    printf 'Profile prompt does not offer both profiles.\n' >&2
    exit 1
fi

generated_config="$(chezmoi --config /dev/null --config-format toml --source "$repo_root" \
    execute-template --init \
    --promptChoice 'Choose a dotfiles profile=cli' <"$config_template")"
if ! grep -Fq 'profile = "cli"' <<<"$generated_config"; then
    printf 'Profile prompt did not save the selected CLI profile.\n' >&2
    exit 1
fi

package_script="$repo_root/.chezmoiscripts/run_onchange_after_install_packages.sh.tmpl"
rendered_package_script="$(chezmoi --source "$repo_root" execute-template <"$package_script")"
test_root="$(mktemp -d)"
trap 'rm -rf -- "$test_root"' EXIT
test_home="$test_root/home"
test_bin="$test_root/bin"
mkdir -p "$test_home/.config/mise" "$test_bin"
: >"$test_home/.config/mise/config.toml"
printf '#!/bin/bash\nprintf "%%s\\n" "$*" >> "$CALL_LOG"\n' >"$test_bin/mise"
chmod +x "$test_bin/mise"
call_log="$test_root/mise.log"
env HOME="$test_home" PATH="$test_bin:/usr/bin:/bin" CALL_LOG="$call_log" \
    bash -c "$rendered_package_script"
expected_log="$test_root/expected-mise.log"
printf 'trust %s\ninstall\n' "$test_home/.config/mise/config.toml" >"$expected_log"
if ! diff -u "$expected_log" "$call_log"; then
    printf 'Package installer did not find mise on PATH and trust the applied config.\n' >&2
    exit 1
fi

cli_dependencies_script="$repo_root/.chezmoiscripts/run_onchange_after_install_cli_dependencies.sh.tmpl"
rendered_cli_dependencies_script="$(chezmoi --source "$repo_root" execute-template <"$cli_dependencies_script")"
if ! bash -n <<<"$rendered_cli_dependencies_script"; then
    printf 'CLI dependency installer has invalid Bash syntax.\n' >&2
    exit 1
fi
for tool in neovim yazi fd fzf lazygit ripgrep zoxide jq; do
    if ! grep -Eq "^${tool} = \"latest\"$" "$repo_root/dot_config/mise/config.toml"; then
        printf 'mise config is missing CLI tool: %s\n' "$tool" >&2
        exit 1
    fi
done
for package in file build-essential gcc make unzip; do
    if ! grep -Fq "$package" "$cli_dependencies_script"; then
        printf 'CLI dependency installer is missing system package: %s\n' "$package" >&2
        exit 1
    fi
done
for package in xclip wl-clipboard; do
    if ! grep -Fq "$package" "$cli_dependencies_script"; then
        printf 'CLI dependency installer is missing clipboard package: %s\n' "$package" >&2
        exit 1
    fi
done
grep -Fq 'powershell.exe' "$repo_root/dot_config/nvim/lua/config/clipboard.lua"
grep -Fq 'vim.g.clipboard = "osc52"' "$repo_root/dot_config/nvim/lua/config/clipboard.lua"
grep -Fq 'vim.opt.clipboard = "unnamedplus"' "$repo_root/dot_config/nvim/lua/config/options.lua"
grep -Fq 'dark = "gruvbox-material"' "$repo_root/dot_config/yazi/theme.toml"
grep -Fq 'vim.g.gruvbox_material_background = "medium"' \
    "$repo_root/dot_config/nvim/lua/plugins/gruvbox_material.lua"
grep -Fq 'vim.opt.background = "dark"' \
    "$repo_root/dot_config/nvim/lua/plugins/gruvbox_material.lua"

bashrc_output="$(env HOME="$test_home" PATH=/usr/bin:/bin SSH_AUTH_SOCK=/dev/null \
    bash --rcfile "$repo_root/dot_bashrc" -ic ':' 2>&1 || true)"
if grep -Fq "$test_home/.cargo/env" <<<"$bashrc_output"; then
    printf 'Bash startup tried to source missing ~/.cargo/env.\n' >&2
    exit 1
fi

browser_output="$(env HOME="$test_home" PATH="$test_bin:/usr/bin:/bin" \
    SSH_AUTH_SOCK=/dev/null BROWSER=host-browser PS1= PROMPT_COMMAND=: \
    bash --rcfile "$repo_root/dot_bashrc" -ic 'printf "%s\\n" "$BROWSER"' 2>/dev/null)"
if [[ "$browser_output" != "host-browser" ]]; then
    printf 'Bash startup overrode the host-provided browser opener: %s\n' "$browser_output" >&2
    exit 1
fi

yazi_target="$test_home/Yazi destination"
mkdir -p "$yazi_target"
printf '%s\n' \
    '#!/usr/bin/env bash' \
    'for arg in "$@"; do' \
    '    [[ "$arg" == --cwd-file=* ]] && cwd_file="${arg#*=}"' \
    'done' \
    'printf "%s\\0" "$YAZI_TARGET" >"$cwd_file"' >"$test_bin/yazi"
chmod +x "$test_bin/yazi"
yazi_output="$(env HOME="$test_home" PATH="$test_bin:/usr/bin:/bin" \
    SSH_AUTH_SOCK=/dev/null YAZI_TARGET="$yazi_target" PS1= PROMPT_COMMAND=: \
    bash --rcfile "$repo_root/dot_bashrc" -ic 'y; pwd' 2>/dev/null)"
if [[ "$(tail -n 1 <<<"$yazi_output")" != "$yazi_target" ]]; then
    printf 'Yazi shell wrapper did not change to the selected directory.\n' >&2
    exit 1
fi

printf 'CLI/Fedora Sway profile checks passed.\n'
