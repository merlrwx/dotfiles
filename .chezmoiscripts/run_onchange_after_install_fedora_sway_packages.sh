#!/usr/bin/env bash

set -euo pipefail

if [[ ! -f /etc/fedora-release ]]; then
    exit 0
fi

packages=(
    alacritty
    blueman
    brightnessctl
    dunst
    fontawesome-6-free-fonts
    grim
    grimshot
    jetbrains-mono-fonts-all
    libnotify
    lxqt-policykit
    pavucontrol
    playerctl
    rofi
    slurp
    sway
    sway-config-fedora
    sway-systemd
    swaybg
    swayidle
    swaylock
    waybar
    wl-clipboard
    xdg-desktop-portal
    xdg-desktop-portal-gtk
    xdg-desktop-portal-wlr
)

sudo dnf install -y "${packages[@]}"
