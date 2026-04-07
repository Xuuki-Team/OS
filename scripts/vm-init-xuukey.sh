#!/bin/bash
# Auto-run on VM boot - load 9p and mount xuukey

# Load 9p modules
modprobe 9p
modprobe 9pnet
modprobe 9pnet_virtio

# Create mount point and mount xuukey
mkdir -p /mnt/xuukey
mount -t 9p -o trans=virtio,version=9p2000.L xuushare /mnt/xuukey

# Show confirmation
echo "====================================="
echo "XUUKEY mounted at /mnt/xuukey"
ls -la /mnt/xuukey
echo "====================================="
echo "Ready to run install script:"
echo "  cd /mnt/xuukey"
echo "  bash install-openclaw-vm-os.sh"
