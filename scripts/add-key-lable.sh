#!/bin/bash                                                                                                                           
# Use the e2label command to label an ext2/3/4 filesystem. Here's a simple bash script to label /dev/sdb1 as XUUKEY:             
                                                                                                                                      
# Check if the device exists                                                                                                          
if [ ! -b /dev/sdb1 ]; then                                                                                                           
  echo "Device /dev/sdb1 not found."                                                                                                  
  exit 1                                                                                                                              
fi                                                                                                                                    
                                                                                                                                      
# Label the partition                                                                                                                 
sudo e2label /dev/sdb1 XUUKEY                                                                                                         
                                                                                                                                      
# Verify the label                                                                                                                    
current_label=$(sudo e2label /dev/sdb1)                                                                                               
echo "The label for /dev/sdb1 is now: $current_label"                                                                                 
                                                                                                                                      

# Make sure the filesystem on /dev/sdb1 is ext2/3/4 before running this script. You can execute the script with bash script_name.sh.     
