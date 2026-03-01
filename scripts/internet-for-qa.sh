# Inside the VM
ip addr add 10.0.0.2/24 dev enp2s0
ip link set enp2s0 up
ip route add default via 10.0.0.1
echo "nameserver 1.1.1.1" > /etc/resolv.conf
