#!/bin/bash

echo "Updating Arch Linux System..."

sudo pacman -Syu --noconfirm

if command -v flatpak &> /dev/null; then
    echo "Updating Flatpak applications..."
    flatpak update -y
fi

if command -v yay &> /dev/null; then
    echo "Updating AUR packages..."
    yay -Syu --noconfirm
fi

sudo pacman -Sc --noconfirm
sudo pacman -Rns $(pacman -Qdtq) --noconfirm

echo "Update completed successfully!"

