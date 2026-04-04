#!/bin/bash
# start-qa-vm.sh

VM_NAME="qa-vm"

# 1. Check if VM exists
if ! sudo virsh dominfo "$VM_NAME" >/dev/null 2>&1; then
    echo "Error: VM '$VM_NAME' not found. Run install-qa-vm.sh first."
    exit 1
fi

# 2. Stop the VM if it's currently running the installer
echo "Stopping $VM_NAME to update boot config..."
sudo virsh destroy "$VM_NAME" 2>/dev/null

# 3. Strip the 'Direct Kernel Boot' settings
# This removes the <kernel>, <initrd>, and <cmdline> tags from the XML
# so libvirt falls back to the standard boot order (Hard Drive)
echo "Removing installer boot overrides..."
sudo virsh edit "$VM_NAME" --expr 'nosave; /domain/os/kernel; /domain/os/initrd; /domain/os/cmdline' >/dev/null 2>&1 || \
sudo virt-xml "$VM_NAME" --edit --boot kernel=,initrd=,cmdline=

# 4. Ensure Hard Drive is the first boot device
sudo virt-xml "$VM_NAME" --edit --boot hd

# 5. Start the VM and connect to console
echo "Booting into your new Arch installation..."
sudo virsh start "$VM_NAME"
sudo virsh console "$VM_NAME"

