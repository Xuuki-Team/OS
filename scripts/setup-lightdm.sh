#!/bin/bash
# setup-lightdm.sh - Configure LightDM WebKit greeter on x230
set -e

echo '=== Setting up LightDM WebKit greeter ==='

# Get repo dir - handle sudo
if [ -n "$SUDO_USER" ]; then
    REPO_DIR="/home/$SUDO_USER/Projects/OS"
else
    REPO_DIR="$HOME/Projects/OS"
fi

# Install packages
echo 'Installing LightDM packages...'
pacman -Sy --noconfirm lightdm lightdm-webkit2-greeter

# Copy theme
echo 'Installing xuuki greeter theme...'
mkdir -p /usr/share/lightdm-webkit/themes/xuuki-greeter
cp "$REPO_DIR/index.html" /usr/share/lightdm-webkit/themes/xuuki-greeter/

# Install session files
echo 'Installing DWM session...'
cp "$REPO_DIR/configs/dwm/start-dwm.sh" /usr/local/bin/
mkdir -p /usr/share/xsessions
cp "$REPO_DIR/configs/lightdm/dwm.desktop" /usr/share/xsessions/
chmod +x /usr/local/bin/start-dwm.sh

# Configure LightDM
echo 'Configuring LightDM...'
cat > /etc/lightdm/lightdm.conf << 'LMDEOF'
[Seat:*]
greeter-session=lightdm-webkit2-greeter
session-wrapper=/etc/lightdm/Xsession

greeter-environment=WEBKIT_DISABLE_DMABUF_RENDERER=1
LMDEOF

cat > /etc/lightdm/lightdm-webkit2-greeter.conf << 'GREETEREOF'
[greeter]
debug_mode = false
detect_theme_errors = true
screensaver_timeout = 300
secure_mode = true
time_format = LT
time_language = auto
webkit_theme = xuuki-greeter

[branding]
background_images = /usr/share/backgrounds
logo = /usr/share/pixmaps/archlinux-logo.svg
user_image = /usr/share/pixmaps/archlinux-user.svg
GREETEREOF

# Enable service
systemctl enable lightdm

echo '=== LightDM setup complete ==='
echo 'Reboot to test greeter'
