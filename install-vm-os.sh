qemu-system-x86_64 -name "arch-vm1" -m 2048 -smp 2 -enable-kvm -cpu host -drive file=arch-vm1.qcow2,format=qcow2 -cdrom archlinux-2026.01.01-x86_64.iso -boot d -net nic -net user -nographic
