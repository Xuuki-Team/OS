# To ensure the VM can access the shared directory /mnt/xuukey, you need to create the directory inside the VM and mount the shared filesystem. Here's how you can automate this process:

#
#  1 Create the Directory: Ensure the directory exists in the VM. You can add a command to create it during the initial setup or in a startup script.
#  2 Mount the Filesystem: Use the mount command to mount the shared directory. You can add this to a script that runs at boot or login.
#
# Here's a simple script you can use inside the VM:


#!/bin/bash

# Ensure that the 9p kernel module is loaded in the VM. You can load it with:                                                                                                                       

                                                                                                                                                                                                  
 modprobe 9p                                                                                                                                                                                      
 modprobe 9pnet                                                                                                                                                                                   
 modprobe 9pnet_virtio                                                                                                                                                                            
                                                                                                                                                                                                  

# Additionally, verify that the xuushare tag is correctly defined in your virt-install command with the --filesystem option. If the issue persists, check the VM's kernel logs using dmesg for any  
# additional error messages related to the 9p filesystem.





# Create the directory if it doesn't exist
mkdir -p /mnt/xuukey

# Mount the shared filesystem
mount -t 9p -o trans=virtio xuushare /mnt/xuukey


# You can place this script in /etc/profile.d/ or as a systemd service to ensure it runs at boot. This will make the shared directory accessible every time the VM starts.
# Script will need to go in customiso to achieve this - for now cp paste


