# OpenClaw VM Recreation

Created: Sun  5 Apr 10:09:02 BST 2026

## Quick Steps
1. Run: ./scripts/install-openclaw-vm.sh
2. Connect console: sudo virsh console openclaw-vm
3. Install Arch: curl http://192.168.1.230:3001/os/i52520M | bash
4. After install: ./scripts/recreate-openclaw-vm.sh
5. Connect: sudo virsh console openclaw-vm

## Login
root/admin, password: x

## Files
- scripts/install-openclaw-vm.sh - Create VM from ISO
- scripts/recreate-openclaw-vm.sh - Fix VM after install
- vm-backup/openclaw-vm.xml - Reference VM config
