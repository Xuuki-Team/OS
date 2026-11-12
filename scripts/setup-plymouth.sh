#!/bin/bash
set -e

# Usage: ./setup-plymouth.sh [spinner]
#   spinner - Use spinner theme (proven working)
#   (no arg) - Use xuuki-splash (default)

THEME="${1:-xuuki-splash}"

echo "=== Setting up Plymouth boot splash ==="
echo "Theme: $THEME"

if [ "$EUID" -ne 0 ]; then
  echo "Error: Must run as root (use sudo)"
  exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# For Intel graphics: force proper i915 driver instead of simple-framebuffer
echo "Configuring Intel graphics driver..."
if ! grep -q "force_probe=1" /etc/modprobe.d/i915.conf 2>/dev/null; then
    echo 'options i915 force_probe=1' > /etc/modprobe.d/i915.conf
fi

# Blacklist simpledrm to prevent fallback framebuffer
if ! grep -q "simpledrm" /etc/modprobe.d/blacklist.conf 2>/dev/null; then
    echo 'blacklist simpledrm' > /etc/modprobe.d/blacklist.conf
fi

# Copy xuuki-splash theme files from repo
echo "Copying xuuki-splash theme files..."
mkdir -p /usr/share/plymouth/themes/xuuki-splash
if [ -d "$SCRIPT_DIR/../configs/plymouth/xuuki-splash" ]; then
    cp "$SCRIPT_DIR/../configs/plymouth/xuuki-splash/"* /usr/share/plymouth/themes/xuuki-splash/
    echo "Theme files copied"
else
    echo "Warning: xuuki-splash not found in repo"
fi

# If using xuuki-splash, overwrite with working script
if [ "$THEME" = "xuuki-splash" ]; then
    echo "Installing working xuuki-splash script..."
    cat > /usr/share/plymouth/themes/xuuki-splash/xuuki-splash.script << 'SCRIPTV3'
# xuuki-splash v3 - working Plymouth JS
Window.SetBackgroundTopColor(0.0, 0.0, 0.0);
Window.SetBackgroundBottomColor(0.0, 0.0, 0.0);
bg.image = Image("background.png");
bg.sprite = Sprite(bg.image);
Plymouth.SetRefreshFunction(refresh_callback);
fun refresh_callback()
{
    bg.sprite.SetX(Window.GetX());
    bg.sprite.SetY(Window.GetY());
}
SCRIPTV3
fi

echo "Setting theme to $THEME..."
plymouth-set-default-theme "$THEME"

echo "Configuring plymouthd..."
# DeviceTimeout is CRITICAL - without it Plymouth won't wait for DRM device
mkdir -p /etc/plymouth
cat > /etc/plymouth/plymouthd.conf << EOF
[Daemon]
Theme=$THEME
ShowDelay=5
DeviceTimeout=8
EOF

echo "Configuring initramfs..."
# Add i915 module
if ! grep -q i915 /etc/mkinitcpio.conf; then
    sed -i 's/^MODULES=(/MODULES=(i915 /' /etc/mkinitcpio.conf
fi

# Add plymouth hook (must be after systemd)
if ! grep -q "base systemd plymouth" /etc/mkinitcpio.conf; then
    sed -i 's/HOOKS=(base /HOOKS=(base systemd plymouth /' /etc/mkinitcpio.conf
fi

# Add two-step.so plugin to FILES (for spinner theme)
if ! grep -q "two-step.so" /etc/mkinitcpio.conf; then
    sed -i 's/^FILES=(/FILES=(\/usr\/lib\/plymouth\/two-step.so /' /etc/mkinitcpio.conf
fi

# Add script.so plugin to FILES (CRITICAL for xuuki-splash theme)
if ! grep -q "script.so" /etc/mkinitcpio.conf; then
    sed -i 's/^FILES=(/FILES=(\/usr\/lib\/plymouth\/script.so /' /etc/mkinitcpio.conf
fi

mkinitcpio -P

echo "Configuring GRUB for quiet splash vt.handoff=7..."
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash vt.handoff=7"/g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

echo "Adding delays to extend splash display..."
# Clear old overrides
rm -rf /etc/systemd/system/plymouth-quit.service.d/
rm -rf /etc/systemd/system/plymouth-quit-wait.service.d/

mkdir -p /etc/systemd/system/plymouth-quit.service.d/
cat > /etc/systemd/system/plymouth-quit.service.d/delay.conf << 'EOF'
[Service]
ExecStartPre=/usr/bin/sleep 5
EOF

mkdir -p /etc/systemd/system/plymouth-quit-wait.service.d/
cat > /etc/systemd/system/plymouth-quit-wait.service.d/delay.conf << 'EOF'
[Service]
ExecStartPre=/usr/bin/sleep 5
TimeoutSec=30
EOF

systemctl daemon-reload

echo "=== Done! Reboot to test $THEME ==="
