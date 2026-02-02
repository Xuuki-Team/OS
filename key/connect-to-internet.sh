#!/bin/bash                                                                                                                                                                                             
source ./config.sh

# Prompt for IP address and network interface                                                       
read -rp "Please enter the IP address (e.g., 192.168.1.101/24): " IP_ADDRESS                        
read -rp "Please enter the network interface (e.g., wlp3s0): " NET_INTERFACE                                                                                                                            

# Configure DNS
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf                                  
systemctl start systemd-resolved                                                               
systemctl start systemd-resolved

# Bring up the network interface
ip link set $NET_INTERFACE up                                                                   

# Configure IP address and route
ip addr add $IP_ADDRESS dev $NET_INTERFACE                                          
ip route add default via 192.168.1.1 dev $NET_INTERFACE                                     
  
# # # Configure WPA supplicant
wpa_passphrase  "$SIDD" "$PASSWORD" > /etc/wpa_supplicant/wpa_supplicant.conf
wpa_supplicant -B -i $NET_INTERFACE -c /etc/wpa_supplicant/wpa_supplicant.conf               

# Start and enable wpa_supplicant service
systemctl start wpa_supplicant                                                                 
systemctl enable wpa_supplicant                                                                

systemctl start sshd
systemctl enable sshd
