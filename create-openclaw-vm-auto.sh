#!/bin/bash
# create-openclaw-vm-auto.sh - Automated Arch VM creation for x230

set -e  # Exit on any error

VM_NAME="openclaw-vm"
DISK_PATH="/var/lib/libvirt/images/${VM_NAME}.qcow2"
RAM_MB=2048
VCPUS=2
ISO_PATH="/var/lib/libvirt/boot/archlinux-2026.02.01-x86_64.iso"

# Check for root/sudo
if [ "$EUID" -ne 0 ]; then 
    echo "Error: This script must be run with sudo"
    echo "Usage: sudo bash create-openclaw-vm-auto.sh"
    exit 1
fi

# Check for ISO
if [ ! -f "$ISO_PATH" ]; then
    echo "Error: ISO not found at $ISO_PATH"
    echo "Download with:"
    echo "  sudo curl -L -o $ISO_PATH https://mirrors.kernel.org/archlinux/iso/2026.02.01/archlinux-2026.02.01-x86_64.iso"
    exit 1
fi

echo "Cleaning up old VM..."
virsh destroy "$VM_NAME" 2>/dev/null || true
virsh undefine "$VM_NAME" --nvram 2>/dev/null || true
rm -f "$DISK_PATH" 2>/dev/null || true

echo "Creating fresh disk..."
qemu-img create -f qcow2 "$DISK_PATH" 20G
chown libvirt-qemu:libvirt-qemu "$DISK_PATH"
chmod 660 "$DISK_PATH"

echo "Creating VM with xuukey auto-mount (4GB RAM)..."
virt-install \
    --name "$VM_NAME" \
    --ram $RAM_MB \
    --vcpus $VCPUS \
    --os-variant archlinux \
    --disk path="$DISK_PATH",format=qcow2,bus=virtio \
    --location "$ISO_PATH",kernel=arch/boot/x86_64/vmlinuz-linux,initrd=arch/boot/x86_64/initramfs-linux.img \
    --network network=default,model=virtio \
    --graphics none \
    --console pty,target_type=serial \
    --noautoconsole \
    --extra-args "console=ttyS0,115200n8 archisobasedir=arch archisolabel=ARCH_202604" \
    --filesystem /mnt/xuukey/,xuushare,mode=mapped \
    --boot hd,menu=off

echo ""
echo "==================================="
echo "  VM '$VM_NAME' CREATED SUCCESSFULLY"
echo "  RAM: ${RAM_MB}MB (2GB RAM + swap)"
echo "==================================="
echo ""
echo "Connect with: sudo virsh console $VM_NAME"
echo ""
echo "Once inside the VM, mount xuukey:"
echo "  modprobe 9p && modprobe 9pnet && modprobe 9pnet_virtio"
echo "  mkdir -p /mnt/xuukey && mount -t 9p -o trans=virtio xuushare /mnt/xuukey"
echo "  ls /mnt/xuukey"
echo ""
echo "Then run install script:"
echo "  bash /mnt/xuukey/install-openclaw-vm-os.sh"
