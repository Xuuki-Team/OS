#!/bin/bash

# Source configuration file

# read -rp "Would you like to enter a source key? (yes/no): " response
#
# if [[ "$response" == "yes" ]]; then
#     read -rp "Name source key configuration file: " sourceKey
#     if [[ -f "$sourceKey" ]]; then
#         source "$sourceKey"
#     else
#         echo "File not found: $sourceKey"
#     fi
# else
#     echo "No source file will be used."
# fi

source /mnt/xuukey/xuukey.conf

# Set console layout and font
loadkeys uk
setfont 

# Update system clock
timedatectl set-timezone Europe/London
timedatectl set-ntp true
timedatectl

# Create partitions
DEVICE="/dev/$DEV_NAME"

# Check if the device exists
if [ ! -b "$DEVICE" ]; then
  echo "Error: Device $DEVICE does not exist."
  exit 1
fi

# Wipe existing partitions
wipefs --all "$DEVICE"
parted "$DEVICE" mklabel msdos

# Create partitions
parted "$DEVICE" mkpart primary 1MiB 2MiB
parted "$DEVICE" set 1 boot on
parted "$DEVICE" mkpart primary linux-swap 2MiB 4098MiB
mkswap "${DEVICE}2"
swapon "${DEVICE}2"
parted "$DEVICE" mkpart primary ext4 4098MiB 100%
mkfs.ext4 "${DEVICE}3"

# Mount the partitions
mount "${DEVICE}3" /mnt/os
 
# Install packages
pacman -Sy
pacman -Sy archlinux-keyring
echo "KEYMAP=uk" > /mnt/os/etc/vconsole.conf
pacstrap -K /mnt/os base base-devel linux linux-firmware git vim wpa_supplicant github-cli grub openssh sudo arch-install-scripts parted github-cli git bitwarden-cli less wget docker python python-pip linux-headers jq libx11 libxft libxinerama xorg-server xorg-xinit libxinerama ttf-dejavu ttf-liberation xorg-xterm lightdm lightdm-slick-greeter plymouth papirus-icon-theme

# Stage Xuuki desktop layer (run from the OS repo checkout; files copied into the target)
# Assumes this script is executed with the OS repo at /mnt/xuukey/OS (xuukey USB) —
# adjust XUUKEY_OS if the checkout lives elsewhere.
XUUKEY_OS="$(cd "$(dirname "$0")/.." && pwd)"
install -D -m 755 "$XUUKEY_OS/configs/dwm/start-dwm.sh" /mnt/os/usr/local/bin/start-dwm.sh
install -D -m 644 "$XUUKEY_OS/configs/lightdm/dwm.desktop" /mnt/os/usr/share/xsessions/dwm.desktop
install -D -m 644 "$XUUKEY_OS/configs/backgrounds" /mnt/os/usr/share/backgrounds/im.jpg
install -D -m 755 "$XUUKEY_OS/configs/systemd/user/dwmblocks.service" /mnt/os/etc/systemd/user/dwmblocks.service
install -d -m 755 /mnt/os/usr/share/plymouth/themes/xuuki-splash
install -m 644 "$XUUKEY_OS/configs/plymouth/xuuki-splash/background.png" /mnt/os/usr/share/plymouth/themes/xuuki-splash/background.png
install -m 644 "$XUUKEY_OS/configs/plymouth/xuuki-splash/xuuki-splash.plymouth" /mnt/os/usr/share/plymouth/themes/xuuki-splash/xuuki-splash.plymouth
install -m 755 "$XUUKEY_OS/configs/plymouth/xuuki-splash/xuuki-splash.script" /mnt/os/usr/share/plymouth/themes/xuuki-splash/xuuki-splash.script
# Configure install system
genfstab -U /mnt/os >> /mnt/os/etc/fstab
  
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

# Xuuki desktop: .xinitrc (dwm if present, xterm fallback)
cat << XINITRC > /home/$NEW_USER/.xinitrc
#!/bin/bash

if command -v dwm >/dev/null 2>&1; then
    exec dwm
fi
exec xterm
XINITRC
chown $NEW_USER:$NEW_USER /home/$NEW_USER/.xinitrc

# LightDM greeter background + enable display manager
mkdir -p /etc/lightdm
cat << GREETER > /etc/lightdm/slick-greeter.conf
[Greeter]
background=/usr/share/backgrounds/im.jpg
GREETER
systemctl enable lightdm

# Plymouth splash (hook must precede mkinitcpio -P)
plymouth-set-default-theme xuuki-splash
if ! grep -q "plymouth" /etc/mkinitcpio.conf; then
    sed -i 's/^HOOKS=(\(.*udev\)\(.*\))$/HOOKS=(\1 plymouth\2)/' /etc/mkinitcpio.conf
fi

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
echo "GRUB_CMDLINE_LINUX_DEFAULT=\"console=tty0 console=ttyS0,115200\"" | sudo tee -a /etc/default/grub
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

# # Make the script executable

chmod +x /mnt/os/root/chroot-script.sh
chmod +x /mnt/os/root/hostname.sh
chmod +x /mnt/os/root/config-bootloader.sh
chmod +x /mnt/os/usr/local/bin/connect-to-internet.sh
 
#Run the script in the chroot environment
arch-chroot /mnt/os /root/chroot-script.sh
arch-chroot /mnt/os /root/hostname.sh
arch-chroot /mnt/os /root/config-bootloader.sh

# Xuuki desktop layer: build dwm + enable user services
git clone -q https://github.com/Xuuki-Team/dwm /mnt/os/root/dwm-build
arch-chroot /mnt/os /bin/bash -lc "cd /root/dwm-build && make clean install"
arch-chroot /mnt/os systemctl --global enable dwmblocks

echo "Unmount everything after the script finishes: umount -R /mnt/os"
