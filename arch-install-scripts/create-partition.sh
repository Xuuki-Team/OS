#!/bin/bash

# List block devices using lsblk and append /dev/ to the names
echo "Available block devices:"
lsblk -d -o NAME,SIZE,TYPE | grep disk
echo

# Prompt user to select a device
read -rp "Please enter the name of the device (e.g., sda): " DEV_NAME
DEVICE="/dev/$DEV_NAME"

# Check if the device exists
if [ ! -b "$DEVICE" ]; then
  echo "Error: Device $DEVICE does not exist."
  exit 1
fi

# Display device details and ask for confirmation
echo
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

# Create Boot Partition (1-200 MiB)
echo "Creating Boot Partition..."
parted "$DEVICE" mkpart primary 1MiB 200MiB
mkfs.ext4 "${DEVICE}1"

# Create the swap partition (4 GiB)
echo "Creating 4 GiB swap partition..."
parted "$DEVICE" mkpart primary linux-swap 200MiB 4296MiB
mkswap "${DEVICE}2"
swapon "${DEVICE}2"
echo "Swap partition created and activated."

# Create the root partition using the remaining space
echo "Creating root partition using remaining space..."
parted "$DEVICE" mkpart primary ext4 4296MiB 100%
mkfs.ext4 "${DEVICE}3"
echo "Root partition created and formatted as ext4."

# Mount the partitions
echo "Mounting partitions..."
mount "${DEVICE}3" /mnt
mkdir /mnt/boot
mount "${DEVICE}1" /mnt/boot

# Display the partition table
lsblk "$DEVICE"

echo "Partitioning and mounting complete!"
