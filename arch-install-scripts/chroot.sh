#!/bin/bash
# Create a temporary script to run in chroot
cat << 'EOF' > /mnt/root/chroot-script.sh
#!/bin/bash
# This script will be run in the chroot environment

# Set up locale
echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_GB.UTF-8" > /etc/locale.conf

# Set up timezone
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc

# Set up hostname
read -rp "Please enter the hostname: " HOSTNAME                                                     
echo "$HOSTNAME" > /etc/hostname                                                                    
echo "127.0.0.1   localhost" >> /etc/hosts
echo "::1         localhost" >> /etc/hosts                                                          
echo "127.0.1.1   $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

# Any other commands to run in the chroot environment
passwd

# Install and configure the bootloader
# Prompt user to select a device
read -rp "Please enter the name of the device (e.g., sda): " DEV_NAME
DEVICE="/dev/$DEV_NAME"
# Check if the device exists
if [ ! -b "$DEVICE" ]; then
  echo "Error: Device $DEVICE does not exist."
  exit 1
fi

grub-install --target=i386-pc $DEVICE
grub-mkconfig -o /boot/grub/grub.cfg

# Prompt for new user name
read -rp "Please enter the new username: " newUser
sudo useradd -m "$newUser"

# Set password for the new user
echo "Please set the password for the new user:"
passwd "$newUser"

# Append the user to the supplementary group(s).
usermod -aG wheel $newUser

# Modify sudoers file to allow wheel group to use sudo without a password
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

# Create .local/bin directory for the new user
mkdir -p /home/$newUser/.local/bin
chown -R $newUser:$newUser /home/$newUser/.local

EOF

# Make the script executable
chmod +x /mnt/root/chroot-script.sh

# Run the script in the chroot environment
arch-chroot /mnt /root/chroot-script.sh

# Clean up
rm /mnt/root/chroot-script.sh
