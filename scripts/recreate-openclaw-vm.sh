#!/bin/bash
# recreate-openclaw-vm.sh - Fix VM after Arch install

VM_NAME="openclaw-vm"
DISK_PATH="/var/lib/libvirt/images/${VM_NAME}.qcow2"

echo "Fixing VM boot and network..."

# Stop VM
sudo virsh destroy $VM_NAME 2>/dev/null || true

# Mount disk
sudo modprobe nbd max_part=8
sudo qemu-nbd --connect=/dev/nbd0 $DISK_PATH
sudo mkdir -p /mnt/vm /mnt/efi
sudo mount /dev/nbd0p2 /mnt/vm
sudo mount /dev/nbd0p1 /mnt/efi

# Create EFI BOOT fallback
echo "Creating EFI fallback..."
sudo mkdir -p /mnt/efi/EFI/BOOT
sudo cp /mnt/efi/EFI/GRUB/grubx64.efi /mnt/efi/EFI/BOOT/BOOTX64.EFI

# Generate SSH keys
if [ ! -f /mnt/vm/etc/ssh/ssh_host_rsa_key ]; then
    sudo chroot /mnt/vm ssh-keygen -A
fi

# Set passwords
echo "Setting passwords..."
sudo chroot /mnt/vm /bin/bash -c 'echo "admin:x" | chpasswd; echo "root:x" | chpasswd'

# Create startup script
sudo tee /mnt/vm/root/startup.sh > /dev/null << 'EOF'
#!/bin/bash
ip link set enp1s0 up 2>/dev/null || ip link set eth0 up 2>/dev/null
ip addr add 192.168.122.100/24 dev enp1s0 2>/dev/null || ip addr add 192.168.122.100/24 dev eth0 2>/dev/null
ip route add default via 192.168.122.1 2>/dev/null
cd /etc/ssh && /usr/bin/sshd
EOF

sudo chmod +x /mnt/vm/root/startup.sh

# Enable serial console
sudo mkdir -p /mnt/vm/etc/systemd/system/getty.target.wants/
sudo ln -sf /usr/lib/systemd/system/serial-getty@.service /mnt/vm/etc/systemd/system/getty.target.wants/serial-getty@ttyS0.service 2>/dev/null || true

# Cleanup
sudo umount /mnt/efi /mnt/vm
sudo qemu-nbd --disconnect /dev/nbd0

# Fix VM XML
echo "Fixing VM XML..."
sudo virsh dumpxml $VM_NAME 2>/dev/null | sed 's|/usr/share/ovmf/x64/OVMF_CODE.fd|/usr/share/ovmf/x64/OVMF_CODE.4m.fd|' | sed 's|/var/lib/libvirt/qemu/nvram/.*_VARS.fd|/usr/share/ovmf/x64/OVMF_VARS.4m.fd|' > /tmp/vm-fixed.xml 2>/dev/null
if [ -f /tmp/vm-fixed.xml ]; then
    sudo virsh undefine $VM_NAME 2>/dev/null || true
    sudo virsh define /tmp/vm-fixed.xml
fi

echo "VM fixed! Starting..."
sudo virsh start $VM_NAME
echo "Connect: sudo virsh console $VM_NAME"
echo "Login: root/admin, Password: x"
