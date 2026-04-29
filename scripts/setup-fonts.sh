#!/bin/bash
# setup-fonts.sh - Install icon fonts for DWM/dwmblocks

set -e

echo "=== Installing Nerd Fonts symbols ==="

# Check if running as root for pacman
if [ "$EUID" -ne 0 ]; then
    echo "Error: Must run as root (use sudo)"
    exit 1
fi

# Install Nerd Fonts symbols
pacman -S --noconfirm ttf-nerd-fonts-symbols

echo "=== Fonts installed ==="
echo "Verify with: fc-list | grep -i nerd"
