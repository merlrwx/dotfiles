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

theme_archive="$repo_root/assets/Gruvbox-Yellow-Dark-Compact-Medium.tar.gz"
expected_theme_sha=5f492971fb0e564323aa81a79d35dafb0bf64ab85b966da69c41f43947954000
actual_theme_sha="$(sha256sum "$theme_archive" | cut -d' ' -f1)"
if [[ "$actual_theme_sha" != "$expected_theme_sha" ]]; then
    printf 'GTK theme checksum mismatch: %s\n' "$actual_theme_sha" >&2
    exit 1
fi

theme_archive_listing="$(tar -tzf "$theme_archive")"
for theme in \
    Gruvbox-Yellow-Dark-Compact-Medium \
    Gruvbox-Yellow-Dark-Compact-Medium-hdpi \
    Gruvbox-Yellow-Dark-Compact-Medium-xhdpi; do
    if ! grep -q "^${theme}/" <<<"$theme_archive_listing"; then
        printf 'GTK theme archive is missing: %s\n' "$theme" >&2
        exit 1
    fi
done

desktop_script="$repo_root/.chezmoiscripts/run_onchange_after_zz_install_gruvbox_desktop.sh.tmpl"
grep -Fq "color-scheme 'prefer-dark'" "$desktop_script"
grep -Fq "gtk-theme 'Gruvbox-Yellow-Dark-Compact-Medium'" "$desktop_script"
grep -Fq "icon-theme 'Gruvbox_Dark'" "$desktop_script"
grep -Fq 'xdg-mime default thunar.desktop inode/directory' "$desktop_script"

printf 'Desktop portability checks passed.\n'
