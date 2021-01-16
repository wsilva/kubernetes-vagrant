#!/bin/sh -eux

# Allow for network forwarding in IP Tables
echo "-------------------------------"
echo "Allow for network forwarding in IP Tables"
echo "-------------------------------"
modprobe overlay
modprobe br_netfilter

# Set up required sysctl params, these persist across reboots.
cat <<EOF >/etc/sysctl.d/99-kubernetes-cri.conf 
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sysctl --system

# kubernetes requires swap off
echo "-------------------------------"
echo "Turning the swap off"
echo "-------------------------------"
swapoff -a
# keep swap off after reboot
sed -i.bak -r 's/(.+ swap .+)/#\1/' /etc/fstab