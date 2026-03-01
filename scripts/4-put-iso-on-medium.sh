#!/bin/bash

# Ensure the correct USB device is used
DEVICE="/dev/sdb"
ISO_FILE="$HOME/xuukiarchiso/out/archlinux-2026.02.26-x86_64.iso"

# Check if the device exists
if [ ! -b "$DEVICE" ]; then
  echo "Error: Device $DEVICE does not exist."
  exit 1
fi

# Write the ISO to the USB stick
echo "Writing $ISO_FILE to $DEVICE..."
sudo dd bs=4M if=$ISO_FILE of=$DEVICE conv=fsync oflag=direct status=progress

# Sync to ensure all data is written
echo "Syncing data to disk..."
sync

echo "ISO has been successfully written to $DEVICE."

