#!/bin/bash

# Set up hostname
sleep 3
read -rp "Please enter the hostname: " HOSTNAME
echo "$HOSTNAME" > /etc/hostname                                                                    
echo "127.0.0.1   localhost" >> /etc/hosts
echo "::1         localhost" >> /etc/hosts                                                          
echo "127.0.1.1   $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

