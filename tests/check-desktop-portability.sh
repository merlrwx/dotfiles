#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
managed="$(chezmoi --source "$repo_root" --override-data '{"profile":"fedora-sway"}' managed)"

required_paths=(
    .config/Thunar/uca.xml
    .config/gtk-3.0/settings.ini
    .config/gtk-4.0/settings.ini
    .config/mimeapps.list
    .config/swaylock/config
    .config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml
    Pictures/wallpaper.jpg
)

for path in "${required_paths[@]}"; do
    if ! grep -Fxq "$path" <<<"$managed"; then
        printf 'Missing managed desktop path: %s\n' "$path" >&2
        exit 1
    fi
done

package_script="$repo_root/.chezmoiscripts/run_onchange_after_install_fedora_sway_packages.sh.tmpl"
for package in thunar thunar-archive-plugin tumbler gvfs gvfs-smb exo xarchiver gtk-murrine-engine; do
    if ! grep -Eq "^[[:space:]]+${package}$" "$package_script"; then
        printf 'Missing Fedora desktop package: %s\n' "$package" >&2
        exit 1
    fi
done

desktop_script="$repo_root/.chezmoiscripts/run_onchange_after_zz_install_gruvbox_desktop.sh.tmpl"
expected_theme_sha=67126883eebaa480aa1ff85e3582aba1c2ea7b44ff41bc1afc139ee77ab05568
grep -Fq 'TheGreatMcPain/gruvbox-material-gtk/archive/bb306ae972273cbfcbf78f8b772662e8b0678d82.tar.gz' "$desktop_script"
grep -Fq "$expected_theme_sha" "$desktop_script"
grep -Fq 'cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles"' "$desktop_script"
grep -Fq 'mv -f -- "$download" "$archive"' "$desktop_script"
grep -Fq 'themes/Gruvbox-Material-Dark' "$desktop_script"
grep -Fq 'icons/Gruvbox-Material-Dark' "$desktop_script"
grep -Fq 's/#282828/__GM_BG0__/g' "$desktop_script"
grep -Fq 's/__GM_BG0__/#1d2021/g' "$desktop_script"
grep -Fq 's/__GM_BG1__/#282828/g' "$desktop_script"
grep -Fq "color-scheme 'prefer-dark'" "$desktop_script"
grep -Fq "gtk-theme 'Gruvbox-Material-Dark'" "$desktop_script"
grep -Fq "icon-theme 'Gruvbox-Material-Dark'" "$desktop_script"
grep -Fq 'gtk-theme-name=Gruvbox-Material-Dark' "$repo_root/dot_config/gtk-3.0/settings.ini"
grep -Fq 'gtk-theme-name=Gruvbox-Material-Dark' "$repo_root/dot_config/gtk-4.0/settings.ini"
grep -Fq 'xdg-mime default thunar.desktop inode/directory' "$desktop_script"

printf 'Desktop portability checks passed.\n'
