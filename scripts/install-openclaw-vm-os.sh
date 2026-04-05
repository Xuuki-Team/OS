#!/bin/bash
# install-openclaw-vm-os.sh - Install Arch Linux for OpenClaw VM
# Optimized for VM environment with Ollama + OpenClaw

set -e

echo "=== OpenClaw VM OS Installer ==="
echo "This script installs Arch Linux optimized for OpenClaw with AI capabilities"

# Configuration
DEVICE="/dev/vda"  # VirtIO disk in VM
HOSTNAME="openclaw-vm"
NEW_USER="admin"
USER_PASSWORD="x"
ROOT_PASSWORD="x"

# Set console layout
loadkeys uk
setfont || true

# Update system clock
timedatectl set-timezone Europe/London
timedatectl set-ntp true

# Create partitions ( simpler for VM - just boot and root )
echo "Creating partitions on $DEVICE..."
wipefs --all "$DEVICE"
parted "$DEVICE" mklabel gpt
parted "$DEVICE" mkpart primary fat32 1MiB 512MiB
parted "$DEVICE" set 1 esp on
parted "$DEVICE" mkpart primary ext4 512MiB 100%

# Format partitions
echo "Formatting partitions..."
mkfs.fat -F32 "${DEVICE}1"
mkfs.ext4 "${DEVICE}2"

# Mount partitions
mount "${DEVICE}2" /mnt
mkdir -p /mnt/boot/efi
mount "${DEVICE}1" /mnt/boot/efi

# Install base system
echo "Installing base packages..."
# sync db
pacman -Sy --noconfirm archlinux-keyring

# Core packages for OpenClaw VM
pacstrap -K /mnt base base-devel linux linux-firmware \
    networkmanager openssh sudo grub efibootmgr \
    git vim curl wget jq docker python python-pip \
    nodejs npm tmux htop git github-cli

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Configure system in chroot
cat << 'CHROOT_EOF' > /mnt/root/install-chroot.sh
#!/bin/bash
set -e

echo "Configuring system..."

# Locale
echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_GB.UTF-8" > /etc/locale.conf

# Console
loadkeys uk

echo "KEYMAP=uk" > /etc/vconsole.conf

# Timezone
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc

# Hostname
echo "openclaw-vm" > /etc/hostname
cat << 'HOSTS' > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   openclaw-vm
HOSTS

# Users
echo "root:x" | chpasswd
useradd -m admin
echo "admin:x" | chpasswd
usermod -aG wheel admin

# Sudo access
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

# Enable services
systemctl enable NetworkManager
systemctl enable sshd
systemctl enable docker

# Install Ollama
echo "Installing Ollama..."
curl -fsSL https://ollama.com/install.sh | sh
systemctl enable ollama

# Install OpenClaw (placeholder - will need actual install)
echo "OpenClaw will be installed after first boot"

# Bootloader
echo "Installing bootloader..."
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

mkinitcpio -P

echo "Chroot configuration complete!"
CHROOT_EOF

chmod +x /mnt/root/install-chroot.sh
arch-chroot /mnt /root/install-chroot.sh

# Unmount
echo "Unmounting..."
umount -R /mnt

echo ""
echo "=== Installation Complete! ==="
echo "Reboot to start the VM"
echo ""
echo "Post-install tasks:"
echo "1. SSH in as admin"
echo "2. Install OpenClaw Gateway"
echo "3. Pull Ollama models: ollama pull kimi-k2.5"
echo ""
