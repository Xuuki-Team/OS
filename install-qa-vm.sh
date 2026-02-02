#!/bin/bash
# install-qa-vm.sh

VM_NAME="qa-vm"  # Changed from testvm
ISO_PATH="/var/lib/libvirt/boot/archlinux-2026.01.01-x86_64.iso"
DISK_PATH="/var/lib/libvirt/images/${VM_NAME}.qcow2"
RAM_MB=2048
VCPUS=2
BRIDGE="br0"

# 1. CLEANUP: Ensure we start with a fresh slate for QA testing
echo "Cleaning up old $VM_NAME..."
sudo virsh destroy "$VM_NAME" 2>/dev/null
sudo virsh undefine "$VM_NAME" 2>/dev/null
sudo rm -f "$DISK_PATH"

# 2. DISK: Create a fresh 20G disk
echo "Creating fresh disk for QA..."
sudo qemu-img create -f qcow2 "$DISK_PATH" 20G

# 3. PERMISSIONS: Ensure libvirt can see the ISO
sudo chown root:libvirt-qemu "$ISO_PATH"
sudo chmod 640 "$ISO_PATH"

# 4. INSTALL: Launch the QA VM
# Note: We keep the xuushare so your identity/setup scripts are available inside
sudo virt-install --name "$VM_NAME" --ram $RAM_MB --vcpus $VCPUS \
    --os-variant archlinux \
    --disk path="$DISK_PATH",format=qcow2 \
    --location "$ISO_PATH",kernel=arch/boot/x86_64/vmlinuz-linux,initrd=arch/boot/x86_64/initramfs-linux.img \
    --network bridge=$BRIDGE \
    --graphics none \
    --console pty,target_type=serial \
    --noautoconsole \
    --extra-args "console=ttyS0,115200n8 archisobasedir=arch archisolabel=ARCH_202601" \
    --filesystem /mnt/xuukey/,xuushare,mode=mapped

echo "QA VM '$VM_NAME' is booting."
echo "Connect with: virsh --connect qemu:///system console $VM_NAME"

