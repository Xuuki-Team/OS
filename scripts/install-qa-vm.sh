#!/bin/bash

# This script automates the setup of a virtual machine (VM) for quality assurance (QA) testing using libvirt and qemu-kvm. Here's a breakdown of the key steps and concepts:
# 
#  1 Cleanup: The script begins by ensuring any existing VM with the name qa-vm is destroyed and undefined, removing any previous configurations. It also deletes the       
#    associated disk file to start fresh.                                                                                                                                   
#  2 Disk Creation: A new 20GB disk image is created in the QCOW2 format, which is efficient for storage and supports features like snapshots.                              
#  3 Permissions: The ISO file, which contains the installation media, is set with appropriate permissions to ensure libvirt can access it.                                 
#  4 VM Installation: The virt-install command is used to create and start the VM:                                                                                          
#     • Name, RAM, and vCPUs: The VM is named qa-vm, allocated 2048 MB of RAM, and assigned 2 virtual CPUs.                                                                 
#     • OS Variant: Specifies the operating system variant, here archlinux.                                                                                                 
#     • Disk and ISO: The disk path and ISO location are specified for the installation.                                                                                    
#     • Network: The VM is connected to a network bridge br0, allowing it to communicate with the host network.                                                             
#     • Graphics and Console: The VM is set to run without a graphical interface, using a serial console for interaction.                                                   
#     • Extra Arguments: Additional kernel parameters are passed to the installer for configuration.                                                                        
#  5 Filesystem Sharing: A host directory is shared with the VM, allowing access to specific files or scripts.                                                              
# 
# Finally, the script provides instructions to connect to the VM's console using virsh, enabling interaction with the VM's terminal. 

# Using the KVM hypervisor in conjunction with libvirt to manage virtual machines. 
# The virsh tool is a command-line interface provided by libvirt that allows you to control and manage VMs. 
# This script, you use virsh to destroy and undefine any existing VM with the name qa-vm, ensuring a clean setup. You also use virt-install, another libvirt tool, to create and configure a
# new VM with specified resources, disk, and network settings. Once the VM is running, you can interact with it using virsh console, which connects you to the VM's terminal.                       

VM_NAME="qa-vm"  # Changed from testvm
ISO_PATH="/var/lib/libvirt/boot/archlinux-2026.02.01-x86_64.iso"
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
    --extra-args "console=ttyS0,115200n8 archisobasedir=arch archisolabel=ARCH_202602" \
    --filesystem /mnt/xuukey/,xuushare,mode=mapped

echo "QA VM '$VM_NAME' is booting."
echo "Connect with: virsh --connect qemu:///system console $VM_NAME"

