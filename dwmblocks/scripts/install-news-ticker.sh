#!/bin/bash
set -euo pipefail

SERVICE_SOURCE="$(dirname "$0")/../systemd/news-ticker.service"
SERVICE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
SERVICE_TARGET="$SERVICE_DIR/news-ticker.service"

install -Dm644 "$SERVICE_SOURCE" "$SERVICE_TARGET"
systemctl --user daemon-reload
systemctl --user enable --now news-ticker.service > /dev/null

printf 'news-ticker.service installed to %s and started via systemd --user.\n' "$SERVICE_TARGET"
