#!/bin/bash
set -e

echo "=== Setting up Plymouth boot splash ==="

if [ "$EUID" -ne 0 ]; then
  echo "Error: Must run as root (use sudo)"
  exit 1
fi

# For Intel graphics: force proper i915 driver instead of simple-framebuffer
echo "Configuring Intel graphics driver..."
if ! grep -q "force_probe=1" /etc/modprobe.d/i915.conf 2>/dev/null; then
    echo 'options i915 force_probe=1' > /etc/modprobe.d/i915.conf
fi

# Blacklist simpledrm to prevent fallback framebuffer
if ! grep -q "simpledrm" /etc/modprobe.d/blacklist.conf 2>/dev/null; then
    echo 'blacklist simpledrm' > /etc/modprobe.d/blacklist.conf
fi

echo "Setting theme to spinner..."
plymouth-set-default-theme spinner

echo "Configuring initramfs..."
# Add i915 module
if ! grep -q i915 /etc/mkinitcpio.conf; then
    sed -i 's/^MODULES=(/MODULES=(i915 /' /etc/mkinitcpio.conf
fi

# Add plymouth hook
if ! grep -q "base plymouth" /etc/mkinitcpio.conf; then
    sed -i 's/HOOKS=(base /HOOKS=(base plymouth /' /etc/mkinitcpio.conf
fi

# Add two-step.so plugin to FILES (required for spinner theme)
if ! grep -q "two-step.so" /etc/mkinitcpio.conf; then
    sed -i 's/^FILES=(/FILES=(\/usr\/lib\/plymouth\/two-step.so /' /etc/mkinitcpio.conf
fi

mkinitcpio -P

echo "Configuring GRUB for quiet splash..."
if ! grep -q "quiet splash" /etc/default/grub; then
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash /' /etc/default/grub
fi
grub-mkconfig -o /boot/grub/grub.cfg

echo "Adding delay to extend splash display..."
mkdir -p /etc/systemd/system/plymouth-quit.service.d/
cat > /etc/systemd/system/plymouth-quit.service.d/delay.conf << 'EOF'
[Service]
ExecStartPre=/usr/bin/sleep 3
EOF
systemctl daemon-reload

echo "=== Done! Reboot to test spinner splash ==="