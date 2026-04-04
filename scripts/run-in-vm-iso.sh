mkdir /mnt/usb
mount -t 9p -o trans=virtio,version=9p2000.L xuushare /mnt/usb
cd /mnt/usb
ls  # Your xuukey files will be right here!

# 1. Mount your USB/Script share
mkdir -p /mnt/usb
mount -t 9p -o trans=virtio,version=9p2000.L xuushare /mnt/usb

# 2. Set up the network (to talk to gateway 10.0.0.1)
ip addr add 10.0.0.2/24 dev enp2s0  # Check name with 'ip link'
ip route add default via 10.0.0.1
echo "nameserver 1.1.1.1" > /etc/resolv.conf

# 3. Inject your Identity (Bitwarden + SSH)
bash /mnt/usb/id.sh

