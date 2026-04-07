#!/bin/bash
# install-openclaw-vm-os.sh - Adapted from i52520M.sh for VM use with virtio (/dev/vda)

# Source configuration file
source /mnt/xuukey/xuukey.conf

# Set console layout and font
loadkeys uk
setfont 

# Update system clock
timedatectl set-timezone Europe/London
timedatectl set-ntp true
timedatectl

# VM ADAPTATION: Use /dev/vda for virtio disks in VMs
# Instead of /dev/$DEV_NAME which may be sda/nvme on physical hardware
DEVICE="/dev/vda"

# Check if the device exists
if [ ! -b "$DEVICE" ]; then
  echo "Error: Device $DEVICE does not exist."
  echo "Available block devices:"
  lsblk
  exit 1
fi

# Wipe existing partitions
wipefs --all "$DEVICE"
parted "$DEVICE" mklabel msdos

# Create partitions (with 4GB swap)
parted "$DEVICE" mkpart primary 1MiB 2MiB
parted "$DEVICE" set 1 boot on
parted "$DEVICE" mkpart primary linux-swap 2MiB 4098MiB
mkswap "${DEVICE}2"
swapon "${DEVICE}2"
parted "$DEVICE" mkpart primary ext4 4098MiB 100%
mkfs.ext4 "${DEVICE}3"

# Mount the partitions
mount "${DEVICE}3" /mnt/os

# VM OPTIMIZATION: Create additional swapfile for heavy pacstrap
# This prevents host OOM when installing many packages
echo "Creating additional swapfile for install phase..."
dd if=/dev/zero of=/mnt/os/swapfile bs=1M count=2048 status=progress
chmod 600 /mnt/os/swapfile
mkswap /mnt/os/swapfile
swapon /mnt/os/swapfile

# Increase swappiness so swap is used more aggressively (helps prevent OOM)
echo "Tuning memory settings..."
echo 80 > /proc/sys/vm/swappiness
swapon -s
 
# Install packages
pacman -Sy
pacman -Sy archlinux-keyring
echo "KEYMAP=uk" > /mnt/os/etc/vconsole.conf
pacstrap -K /mnt/os base base-devel linux linux-firmware git vim wpa_supplicant github-cli grub openssh sudo arch-install-scripts parted github-cli git bitwarden-cli less wget docker python python-pip linux-headers jq libx11 libxft libxinerama xorg-server xorg-xinit libxinerama ttf-dejavu ttf-liberation

# Configure install system
genfstab -U /mnt/os >> /mnt/os/etc/fstab

# Enable swapfile on boot
echo "/swapfile none swap defaults 0 0" >> /mnt/os/etc/fstab

# Chroot and configure system
cat << EOF > /mnt/os/root/chroot-script.sh
#!/bin/bash

# Set up locale
echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_GB.UTF-8" > /etc/locale.conf

# Set up timezone
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc
 
# Set root password
echo "root:$ROOT_PASSWORD" | chpasswd

# Create new user
useradd -m "$NEW_USER"
echo "$NEW_USER:$USER_PASSWORD" | chpasswd
usermod -aG wheel $NEW_USER

# Modify sudoers file
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

# Create .local/bin directory for the new user
mkdir -p /home/$NEW_USER/.local/bin
chown -R $NEW_USER:$NEW_USER /home/$NEW_USER/.local

echo "KEYMAP=uk" > /etc/vconsole.conf
mkinitcpio -P

EOF

cat << EOF > /mnt/os/root/hostname.sh
#!/bin/bash

# Set up hostname
echo "$HOSTNAME" > /etc/hostname
echo "127.0.0.1   localhost" >> /etc/hosts
echo "::1         localhost" >> /etc/hosts
echo "127.0.1.1   $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts
EOF

cat << EOF > /mnt/os/root/config-bootloader.sh

# Install and configure the bootloader
grub-install --target=i386-pc $DEVICE

# Enable serial console in GRUB (append if not exists)grep -q "^GRUB_TERMINAL=" /etc/default/grub || echo GRUB_TERMINAL="console serial" >> /etc/default/grubgrep -q "^GRUB_SERIAL_COMMAND=" /etc/default/grub || echo GRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1" >> /etc/default/grubgrep -q "^GRUB_CMDLINE_LINUX_DEFAULT=" /etc/default/grub && sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="console=tty0 console=ttyS0,115200"/" /etc/default/grub || echo GRUB_CMDLINE_LINUX_DEFAULT="console=tty0 console=ttyS0,115200" >> /etc/default/grub

grub-mkconfig -o /boot/grub/grub.cfg

EOF

cat << EOF > /mnt/os/usr/local/bin/connect-to-internet.sh
#!/bin/bash

# Prompt for IP address and network interface
read -rp "Please enter the IP address (e.g., 192.168.1.101/24): " IP_ADDRESS
read -rp "Please enter the network interface (e.g., wlp3s0): " NET_INTERFACE

# Configure DNS
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
systemctl start systemd-resolved
systemctl start systemd-resolved

# Bring up the network interface
ip link set "$NET_INTERFACE" up

# Configure IP address and route
ip addr add "$IP_ADDRESS" dev "$NET_INTERFACE"
ip route add default via 192.168.1.1 dev "$NET_INTERFACE"

# Configure WPA supplicant
wpa_passphrase "$SSID" "$PSK" > /etc/wpa_supplicant/wpa_supplicant.conf
wpa_supplicant -B -i "$NET_INTERFACE" -c /etc/wpa_supplicant/wpa_supplicant.conf

# Start and enable wpa_supplicant service
systemctl start wpa_supplicant
systemctl enable wpa_supplicant

systemctl start sshd
systemctl enable sshd
EOF

# Make the scripts executable
chmod +x /mnt/os/root/chroot-script.sh
chmod +x /mnt/os/root/hostname.sh
chmod +x /mnt/os/root/config-bootloader.sh
chmod +x /mnt/os/usr/local/bin/connect-to-internet.sh
 
# Run the scripts in the chroot environment
arch-chroot /mnt/os /root/chroot-script.sh
arch-chroot /mnt/os /root/hostname.sh
arch-chroot /mnt/os /root/config-bootloader.sh

echo "Unmount everything after the script finishes: umount -R /mnt/os"

# FIX Attempt 6: Enable serial console login (like Arch ISO)
# The ISO spawns getty on ttyS0; we need to add it to installed system
arch-chroot /mnt/os systemctl enable serial-getty@ttyS0.service
# FIX added

# FIX Attempt 7: Mount proc/sys/dev before enabling systemd services
mount -t proc proc /mnt/os/proc && mount -t sysfs sys /mnt/os/sys && mount --bind /dev /mnt/os/dev
# Now enable serial getty with proper env
arch-chroot /mnt/os systemctl enable serial-getty@ttyS0.service
# FIX added
