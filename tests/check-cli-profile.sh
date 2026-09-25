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

printf 'CLI/Fedora Sway profile checks passed.\n'
