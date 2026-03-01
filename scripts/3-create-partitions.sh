#!/bin/bash

# Set the device (your USB drive)
DEVICE="/dev/sdb"

# Ensure the device exists
if [ ! -b "$DEVICE" ]; then
  echo "Error: Device $DEVICE does not exist."
  exit 1
fi

sudo wipefs --all /dev/sdb
sudo dd if=/dev/zero of=/dev/sdb bs=512 count=1

# Unmount the device before partitioning
echo "Unmounting all partitions on $DEVICE..."
sudo umount ${DEVICE}* &> /dev/null

# Create a new partition table (GPT for modern systems)
echo "Creating new GPT partition table on $DEVICE..."
sudo parted $DEVICE mklabel gpt

# Creating a primary partition (ext4 or for bootable ISO)
echo "Creating primary partition (size: 100%)..."
sudo parted $DEVICE mkpart primary ext4 1MiB 100%

# Format the partition with ext4
echo "Formatting /dev/sdb1 as ext4..."
sudo mkfs.ext4 ${DEVICE}1

# Display the new partition layout
echo "Partitioning complete. New partition layout:"
lsblk $DEVICE

echo "Done!"

