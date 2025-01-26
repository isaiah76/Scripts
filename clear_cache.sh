#!/bin/bash

# Clear pacman cache
echo "Cleaning pacman cache..."
sudo pacman -Scc --noconfirm

# Clean the AUR helper cache (if you use yay or paru)
echo "Cleaning AUR helper cache..."
yay -Scc --noconfirm  # or use paru if you prefer

# Clear thumbnail cache
echo "Cleaning thumbnail cache..."
rm -rf ~/.cache/thumbnails/*

# Clear font cache
echo "Cleaning font cache..."
fc-cache -r

# Clean the browser cache (e.g., Firefox)
echo "Cleaning Firefox cache..."
rm -rf ~/.cache/mozilla/firefox/*

# Optional: Remove unused packages
echo "Removing unused packages..."
sudo pacman -Rns $(pacman -Qdtq) --noconfirm

echo "clear cache complete"

