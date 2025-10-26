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
                                                                                                                                                                     
source /mnt/xuukey/1.conf

# Set console layout and font                                                                                                                                        
loadkeys uk                                                                                                                                                          
setfont ter-132b                                                                                                                                                     
                                                                                                                                                                     
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
mount "${DEVICE}3" /mnt                                                                                                                                              
                                                                                                                                                                     
# Install packages                                                                                                                                                   
pacman -Sy                                                                                                                                                           
pacstrap -K /mnt base base-devel linux linux-firmware git vim wpa_supplicant github-cli grub openssh sudo arch-install-scripts parted github-cli git bitwarden-cli less wget docker python python-pip linux-headers

# Configure install system                                                                                                                                           
genfstab -U /mnt >> /mnt/etc/fstab                                                                                                                                   
                                                                                                                                                                     
# Chroot and configure system                                                                                                                                        
cat << EOF > /mnt/root/chroot-script.sh                                                                                                                            
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
EOF

                                                                                                                                                                     
cat << EOF > /mnt/root/hostname.sh                                                                                                                                 
#!/bin/bash                                                                                                                                                          
                                                                                                                                                                     
# Set up hostname                                                                                                                                                    
echo "$HOSTNAME" > /etc/hostname                                                                                                                                     
echo "127.0.0.1   localhost" >> /etc/hosts                                                                                                                           
echo "::1         localhost" >> /etc/hosts                                                                                                                           
echo "127.0.1.1   $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts                                                                                                     
EOF
                                                                                                                                                                      
cat << EOF > /mnt/root/config-bootloader.sh                                                                                                                          
                                                                                                                                                                     
# Install and configure the bootloader                                                                                                                               
grub-install --target=i386-pc $DEVICE                                                                                                                                
grub-mkconfig -o /boot/grub/grub.cfg                                                                                                                                 
                                                                                                                                                                     
EOF


cat << EOF > /mnt/usr/local/bin/connect-to-internet.sh                                             
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
                                                                                                                                                                   
chmod +x /mnt/root/chroot-script.sh                                                                                                                                  
chmod +x /mnt/root/hostname.sh                                                                                                                                       
chmod +x /mnt/root/config-bootloader.sh                                                                                                                              
chmod +x /mnt/usr/local/bin/connect-to-internet.sh
                                                                                                                                                                     
# Run the script in the chroot environment                                                                                                                           
arch-chroot /mnt /root/chroot-script.sh                                                                                                                              
arch-chroot /mnt /root/hostname.sh                                                                                                                                   
arch-chroot /mnt /root/config-bootloader.sh                                                                                                                          
                                                                                                                                                                     
# echo "Unmount everything after the script finishes: umount -R /mnt"                                                                                                  
