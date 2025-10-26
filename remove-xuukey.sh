#!/bin/bash                                                                                                                                                          
                                                                                                                                                                      
# Define the target label                                                                                                                                            
TARGET_LABEL="XuuKey"                                                                                                                                                
                                                                                                                                                                     
# Find the device path                                                                                                                                               
DEVICE_PATH=$(lsblk -o LABEL,PATH | grep "$TARGET_LABEL" | awk '{print $2}')                                                                                         
                                                                                                                                                                     
# Check if the device was found                                                                                                                                      
if [ -z "$DEVICE_PATH" ]; then                                                                                                                                       
  echo "Device with label '$TARGET_LABEL' not found."                                                                                                                
  exit 1                                                                                                                                                             
fi                                                                                                                                                                   
                                                                                                                                                                    
## Mount the device                                                                                                                                                   
MOUNT_POINT="/mnt/xuukey"
sudo umount "$MOUNT_POINT"                                                                                                                             
