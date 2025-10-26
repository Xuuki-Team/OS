#!/bin/bash                                                                                                                                                          
                                                                                                                                                                     
# Define the target label                                                                                                                                            
TARGET_LABEL="XuuKey"                                                                                                                                                
MOUNT_POINT="/mnt/xuukey"                                                                                                                                                                   

# Function to mount the device                                                                                                                                       
mount_device() {                                                                                                                                                     
  echo "Mount device"
  DEVICE_PATH=$(lsblk -o LABEL,PATH | grep "$TARGET_LABEL" | awk '{print $2}')
  echo "$DEVICE_PATH"
  
  if [ -n "$DEVICE_PATH" ]; then                                                                                                                                     
    echo "Mounting device with label '$TARGET_LABEL'..."                                                                                                             
    sudo mkdir $MOUNT_POINT
    sleep 1
    sudo mount "$DEVICE_PATH" "$MOUNT_POINT"                                                                                                                         
    sleep 3
    bash $MOUNT_POINT/connect-to-internet.sh
    sleep 3
    bash $MOUNT_POINT/call-api.sh
  else                                                                                                                                                               
    echo "Device with label '$TARGET_LABEL' not found."                                                                                                              
  fi                                                                                                                                                                 
}                                                                                                                                                                    
                                                                                                                                                                     
# Listen for device changes                                                                                                                                          
while true; do                                                                                                                                                       
  echo "Lock..."
  inotifywait -e create,delete /dev                                                                                                                                  
  echo " "
  echo "Check if key is inserted..."
  sleep 1
  mount_device                                                                                                                                                       
done

