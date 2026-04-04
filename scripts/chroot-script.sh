#!/bin/bash
# This script will be run in the chroot environment

# Set up locale
echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_GB.UTF-8" > /etc/locale.conf

# Set up timezone
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc

# Set root password                                                                                                    
passwd

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

