#!/bin/bash
# build-dwm.sh - Build and install DWM with admin config (minimal, Nerd Fonts)

set -e

REPO_DIR="${1:-$HOME/Projects/OS}"

echo "=== Building DWM (admin config) ==="

if [ ! -d "$REPO_DIR/configs/dwm-source" ]; then
    echo "Error: $REPO_DIR/configs/dwm-source not found"
    exit 1
fi

# Ensure dwm source exists
if [ ! -d "$HOME/Projects/dwm" ]; then
    echo "Cloning dwm source..."
    git clone https://git.suckless.org/dwm "$HOME/Projects/dwm"
fi

cd "$HOME/Projects/dwm"

# Copy admin config
cp "$REPO_DIR/configs/dwm-source/config.h" config.h

# Build and install
make clean
make
sudo make install

echo "=== DWM installed ==="
echo "Tags: terminal, dev, web (minimal admin config)"
echo "Fonts: monospace + Nerd Font symbols"
