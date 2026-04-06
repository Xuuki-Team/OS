#!/bin/bash
# create-openclaw-vm.sh - Create OpenClaw VM for x230

VM_NAME="openclaw-vm"
DISK_PATH="/var/lib/libvirt/images/${VM_NAME}.qcow2"
RAM_MB=4096
VCPUS=2

# Check for ISO
ISO_PATH="/var/lib/libvirt/boot/archlinux-2026.02.01-x86_64.iso"
if [ ! -f "$ISO_PATH" ]; then
    echo "Error: ISO not found at $ISO_PATH"
    exit 1
fi

# Clean up any existing VM
echo "Cleaning up old $VM_NAME..."
virsh destroy "$VM_NAME" 2>/dev/null
virsh undefine "$VM_NAME" --nvram 2>/dev/null
rm -f "$DISK_PATH"

# Create fresh 20G disk
echo "Creating disk..."
qemu-img create -f qcow2 "$DISK_PATH" 20G
chown libvirt-qemu:libvirt-qemu "$DISK_PATH"
chmod 660 "$DISK_PATH"

echo "Creating VM with virt-install..."
echo "You'll need to manually install Arch Linux."
echo "Use: ssh -t admin@192.168.1.247 'sudo virsh console openclaw-vm'"

virt-install \
    --name "$VM_NAME" \
    --ram $RAM_MB \
    --vcpus $VCPUS \
    --os-variant archlinux \
    --disk path="$DISK_PATH",format=qcow2,bus=virtio \
    --cdrom "$ISO_PATH" \
    --network network=default,model=virtio \
    --graphics none \
    --console pty,target_type=serial \
    --noautoconsole \
    --boot cdrom,hd

echo ""
echo "VM '$VM_NAME' created."
echo "Connect with: virsh console $VM_NAME"
echo "Check IP with: virsh net-dhcp-leases default"
