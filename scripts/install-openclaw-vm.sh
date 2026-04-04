#!/bin/bash
# install-openclaw-vm.sh - Create OpenClaw VM with working console output
# Based on working QA VM configuration

VM_NAME="openclaw-vm"
ISO_PATH="/var/lib/libvirt/images/archlinux-2026.02.26-x86_64.iso"
DISK_PATH="/var/lib/libvirt/images/${VM_NAME}.qcow2"
RAM_MB=4096
VCPUS=2

# 1. CLEANUP: Remove old VM if exists
echo "Cleaning up old $VM_NAME..."
sudo virsh destroy "$VM_NAME" 2>/dev/null
sudo virsh undefine "$VM_NAME" 2>/dev/null
sudo rm -f "$DISK_PATH"

# 2. DISK: Create a fresh 20G disk
echo "Creating fresh disk..."
sudo qemu-img create -f qcow2 "$DISK_PATH" 20G

# 3. PERMISSIONS: Ensure libvirt can access the ISO
sudo chown root:libvirt-qemu "$ISO_PATH" 2>/dev/null || true
sudo chmod 640 "$ISO_PATH" 2>/dev/null || true

# 4. Ensure xuukey config exists
if [ ! -f /mnt/xuukey/xuukey.conf ]; then
    echo "Creating xuukey config..."
    sudo mkdir -p /mnt/xuukey
    sudo cp /mnt/xuukey.conf /mnt/xuukey/xuukey.conf 2>/dev/null || echo "Warning: No xuukey.conf found"
fi

# 5. INSTALL: Launch the VM with console output enabled
# Using --location (not --cdrom) for console output
# Using --extra-args for serial console
# Using --filesystem to mount xuukey share
echo "Creating VM $VM_NAME..."
sudo virt-install --name "$VM_NAME" --ram $RAM_MB --vcpus $VCPUS \
    --os-variant archlinux \
    --disk path="$DISK_PATH",format=qcow2 \
    --location "$ISO_PATH",kernel=arch/boot/x86_64/vmlinuz-linux,initrd=arch/boot/x86_64/initramfs-linux.img \
    --network network=default \
    --graphics none \
    --console pty,target_type=serial \
    --noautoconsole \
    --extra-args "console=ttyS0,115200n8 archisobasedir=arch archisolabel=ARCH_202602" \
    --filesystem /mnt/xuukey,xuushare,mode=mapped

echo ""
echo "VM '$VM_NAME' is booting."
echo "Connect with: sudo virsh console $VM_NAME"
echo ""
echo "Once inside, run: curl http://192.168.1.230:3001/os/i52520M | bash"
