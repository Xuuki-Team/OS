#!/bin/bash
set -e
echo '=== OpenClaw VM OS Installer (BIOS/MBR) ==='
DEVICE='/dev/vda'
HOSTNAME='claw'
NEW_USER='admin'
USER_PASSWORD='x'
ROOT_PASSWORD='x'

echo 'Downloading config...'
curl -s http://192.168.1.247:3001/os/xuukey.conf -o /tmp/xuukey.conf 2>/dev/null || echo 'Using defaults'
source /tmp/xuukey.conf 2>/dev/null || true
DEVICE="/dev/${DEV_NAME:-vda}"
HOSTNAME=${HOSTNAME:-claw}
NEW_USER=${NEW_USER:-admin}
USER_PASSWORD=${USER_PASSWORD:-x}
ROOT_PASSWORD=${ROOT_PASSWORD:-x}

echo "Host: $HOSTNAME, User: $NEW_USER, Device: $DEVICE"

loadkeys uk 2>/dev/null || true
timedatectl set-timezone Europe/London
timedatectl set-ntp true

echo 'Creating MBR partitions...'
wipefs --all --force $DEVICE
parted -s $DEVICE mklabel msdos
parted -s $DEVICE mkpart primary 1MiB 2MiB
parted -s $DEVICE set 1 boot on
parted -s $DEVICE mkpart primary linux-swap 2MiB 4098MiB
parted -s $DEVICE mkpart primary ext4 4098MiB 100%
mkswap ${DEVICE}2
swapon ${DEVICE}2
mkfs.ext4 -F ${DEVICE}3
mount ${DEVICE}3 /mnt

echo 'Installing packages...'
pacman -Sy --noconfirm archlinux-keyring 2>&1 | tail -3
pacstrap -K /mnt base base-devel linux linux-firmware networkmanager openssh sudo grub git vim curl wget docker python python-pip nodejs npm tmux htop github-cli 2>&1 | tail -5

echo 'Configuring system...'
genfstab -U /mnt >> /mnt/etc/fstab

mkdir -p /mnt/root

# Use 'EOF' with single quotes to prevent expansion here - we'll use actual values
cat > /mnt/root/chroot.sh << EOF
#!/bin/bash
locale-gen
echo 'LANG=en_GB.UTF-8' > /etc/locale.conf
echo 'KEYMAP=uk' > /etc/vconsole.conf
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc
echo '$HOSTNAME' > /etc/hostname
echo '127.0.0.1 localhost' > /etc/hosts
echo '::1 localhost' >> /etc/hosts
echo '127.0.1.1 $HOSTNAME' >> /etc/hosts
echo 'root:$ROOT_PASSWORD' | chpasswd
useradd -m '$NEW_USER'
echo '$NEW_USER:$USER_PASSWORD' | chpasswd
usermod -aG wheel '$NEW_USER'
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
systemctl enable NetworkManager
systemctl enable sshd
systemctl enable serial-getty@ttyS0.service
mkdir -p /etc/default/grub.d
cat > /etc/default/grub.d/99-serial.cfg << GRUBCONF
GRUB_TERMINAL="console serial"
GRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"
GRUB_CMDLINE_LINUX_DEFAULT="console=tty0 console=ttyS0,115200"
GRUBCONF
grub-install --target=i386-pc $DEVICE
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -P
EOF

chmod +x /mnt/root/chroot.sh

mount -t proc proc /mnt/proc
mount -t sysfs sys /mnt/sys
mount --bind /dev /mnt/dev
mount --bind /dev/pts /mnt/dev/pts 2>/dev/null || true

arch-chroot /mnt /root/chroot.sh

umount -R /mnt
echo '=== INSTALL COMPLETE ==='
echo 'Serial console configured - login should appear on virsh console'
