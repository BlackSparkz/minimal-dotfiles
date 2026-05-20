#!/usr/bin/env bash

set -euo pipefail

printf "[+] Starting minimal Arch setup...\n"
printf "[+] Installing base packages...\n"
sudo pacman -S --needed --noconfirm base-devel stow eza git

printf "[+] Verifying whether yay is installed or not...\n"
if ! command -v yay &>/dev/null; then
  printf "[!] yay not found\n"
  printf "[+] Installing yay...\n"
  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' EXIT
  git clone https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin"
  (cd "$tmpdir/yay-bin" && makepkg -si --noconfirm)
else
  printf "[=] yay already installed\n"
fi

printf "[+] Creating config directories...\n"
mkdir -p ~/.local/share/fonts

DOTFILES="$HOME/minimal-dotfiles/"

if [ -d "$DOTFILES" ]; then
  printf "[+] Applying dotfiles...\n"
  bash "$DOTFILES/stow-configs.sh"

  printf "[+] Copying fonts and wallpapers...\n"
  cp -r "$DOTFILES/Configs/fonts/." ~/.local/share/fonts/
  cp -r "$DOTFILES/Wallpapers" ~/

  pkglist="$DOTFILES/Configs/packages/pkglist.txt"
  if [ -f "$pkglist" ]; then
    printf "[+] Installing packages from list...\n"
    xargs yay -S --needed --answerclean None --answerdiff None --noconfirm < "$pkglist"
  fi

else
  printf "[!] Dotfiles repo not found at $DOTFILES — skipping dotfiles, resources, and package list.\n"
fi

if ! pacman -Q bluez bluez-utils &>/dev/null; then
  yay -S --needed --answerclean None --answerdiff None --noconfirm bluez bluez-utils && printf "[+] bluez and bluez-utils installed successfully\n"
else
  printf "[✓] bluez and bluez-utils already installed\n"
fi

if pacman -Q pipewire pipewire-pulse wireplumber &>/dev/null; then
  printf "[✓] pipewire pipewire-pulse wireplumber already installed\n"
else
  printf "[+] Installing pipewire pipewire-pulse wireplumber....\n"
  yay -S --needed --answerclean None --answerdiff None --noconfirm pipewire pipewire-pulse wireplumber
fi

init=$(ps -p 1 -o comm=)
if [[ "$init" == "systemd" ]]; then
  printf "[+] Enabling services...\n"
  sudo systemctl enable --now bluetooth.service
  systemctl --user enable --now mako.service
  systemctl --user enable --now mango.service
  sudo rfkill unblock bluetooth || true
else
  printf "[!] Skipping....\n"
  printf "[!] System is not running on $init\n"
fi

printf "[+] Fixing bash config\n"
if [[ -f "$HOME/.config/Scripts/bashfix.sh" ]]; then
  bash "$HOME/.config/Scripts/bashfix.sh"
else
  printf "bashfix.sh not found\n"
fi

printf "[✓] Setup completed successfully!\n"
printf "\n"
