#!/bin/bash

read -rp "Would you like to enter a source file? (yes/no): " response                                                  
                                                                                                                        
if [[ "$response" == "yes" ]]; then                                                                                    
    read -rp "Please enter source: " sourceFile                                                                        
    if [[ -f "$sourceFile" ]]; then                                                                                    
        source "$sourceFile"                                                                                           
    else                                                                                                               
        echo "File not found: $sourceFile"                                                                             
    fi                                                                                                                 
else                                                                                                                   
    echo "No source file will be used."                                                                                
fi 

echo "Set console layout and font"
loadkeys uk
setfont ter-132b

echo "Update system clock"
timedatectl set-timezone Europe/London
timedatectl set-ntp true
timedatectl

echo "Create partitions"
# List block devices using lsblk and append /dev/ to the names                                                                      
echo "Available block devices:"                                                                                                     
lsblk -d -o NAME,SIZE,TYPE | grep disk                                                                                              

# Prompt user to select a device                                                                                                    
read -rp "Please enter the name of the device (e.g., sda): " DEV_NAME                                                               
DEVICE="/dev/$DEV_NAME"                                                                                                             
                                                                                                                                    
# Check if the device exists                                                                                                        
if [ ! -b "$DEVICE" ]; then                                                                                                         
  echo "Error: Device $DEVICE does not exist."                                                                                      
  exit 1                                                                                                                            
fi                                                                                                                                  
                                                                                                                                    
# Display device details and ask for confirmation                                                                                   

lsblk "$DEVICE"                                                                                                                     
read -rp "Are you sure you want to wipe all partitions on $DEVICE? This action is irreversible! (yes/no): " CONFIRM                 
                                                                                                                                    
if [ "$CONFIRM" != "yes" ]; then                                                                                                    
  echo "Operation cancelled."                                                                                                       
  exit 1                                                                                                                            
fi                                                                                                                                  
                                                                                                                                    
# Clear any existing partitions on the disk                                                                                         
echo "Wiping existing partitions on $DEVICE..."                                                                                     
wipefs --all "$DEVICE"                                                                                                              
                                                                                                                                    
parted "$DEVICE" mklabel msdos
                                                                                                                                    
# Start partitioning                                                                                                                
echo "Creating partitions on $DEVICE..."                                                                                            
                                                                                                                                    
# Create BIOS boot partition (1 MiB)                                                                                                
echo "Creating BIOS boot partition..."                                                                                              
parted "$DEVICE" mkpart primary 1MiB 2MiB                                                                                           
parted "$DEVICE" set 1 boot on                                                                                    
                                                                                                                                    
# Create the swap partition (4 GiB)                                                                                                 
echo "Creating swap partition..."                                                                                                   
parted "$DEVICE" mkpart primary linux-swap 2MiB 4098MiB                                                                             
mkswap "${DEVICE}2"                                                                                                                 
swapon "${DEVICE}2"                                                                                                                 
echo "Swap partition created and activated."                                                                                        
                                                                                                                                    
# Create the root partition using the remaining space                                                                               
echo "Creating root partition using remaining space..."                                                                             
parted "$DEVICE" mkpart primary ext4 4098MiB 100%                                                                                   
mkfs.ext4 "${DEVICE}3"                                                                                                              
echo "Root partition created and formatted as ext4."                                                                                
                                                                                                                                    
# Mount the partitions                                                                                                              
echo "Mounting partitions..."                                                                                                       
mount "${DEVICE}3" /mnt                                                                                                             
                                                                                                                                    
# Display the partition table                                                                                                       
lsblk "$DEVICE"                                                                                                                     
                                                                                                                                    
echo "Partitioning and mounting complete!"                                                                                          
# Install packages
echo "Install packages"
pacman -Sy
pacstrap -K /mnt base base-devel linux linux-firmware git vim wpa_supplicant github-cli grub openssh sudo arch-install-scripts parted github-cli git bitwarden-cli jq less wget docker python python-pip linux-headers csound

echo "Configure install system"
genfstab -U /mnt >> /mnt/etc/fstab

echo "Chroot"
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

echo "Script to add to install os"
cat << 'EOF' > /mnt/root/connect-to-internet.sh                                             
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

echo "Unmount everything after the script finishes: umount -R /mnt"
