#!/bin/bash
# create-openclaw-vm-auto.sh - Automated Arch VM creation for x230

VM_NAME="openclaw-vm"
DISK_PATH="/var/lib/libvirt/images/${VM_NAME}.qcow2"
RAM_MB=4096
VCPUS=2
ISO_PATH="/var/lib/libvirt/boot/archlinux-2026.02.01-x86_64.iso"

# Cleanup
virsh destroy "$VM_NAME" 2>/dev/null
virsh undefine "$VM_NAME" --nvram 2>/dev/null
rm -f "$DISK_PATH"

# Create disk
qemu-img create -f qcow2 "$DISK_PATH" 20G
chown libvirt-qemu:libvirt-qemu "$DISK_PATH"
chmod 660 "$DISK_PATH"

# Create VM with direct kernel boot for installation
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
    --extra-args "console=ttyS0,115200n8 archisobasedir=arch archisolabel=ARCH_202602" \
    --boot hd,cdrom

echo "VM '$VM_NAME' created with kernel boot"
