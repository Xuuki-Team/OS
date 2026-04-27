#!/bin/bash
# setup-plymouth.sh - Configure Plymouth boot splash on x230
set -e

echo '=== Setting up Plymouth boot splash ==='

if [ '$EUID' -ne 0 ]; then
  echo 'Error: Must run as root (use sudo)'
  exit 1
fi

REPO_DIR='$HOME/Projects/OS'

if ! command -v plymouth-set-default-theme >/dev/null 2>&1; then
    echo 'Installing Plymouth...'
    pacman -Sy --noconfirm plymouth
fi

echo 'Installing theme...'
mkdir -p /usr/share/plymouth/themes/
cp -r '$REPO_DIR/configs/plymouth/xuuki-splash' /usr/share/plymouth/themes/

plymouth-set-default-theme xuuki-splash

cat > /etc/plymouth/plymouthd.conf << 'EOF'
[Daemon]
Theme=xuuki-splash
ShowDelay=5
EOF

echo 'Configuring initramfs...'
if ! grep -q 'i915' /etc/mkinitcpio.conf; then
    sed -i 's/^MODULES=(/MODULES=(i915 /' /etc/mkinitcpio.conf
fi

if ! grep -q 'plymouth' /etc/mkinitcpio.conf; then
    sed -i 's/HOOKS=(base /HOOKS=(base plymouth /' /etc/mkinitcpio.conf
fi

mkinitcpio -P
systemctl enable plymouth

echo '=== Done! Reboot to test ==='
