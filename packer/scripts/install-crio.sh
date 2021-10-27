#!/bin/sh -eux

# Setup cri-o
echo "-------------------------------"
echo "Setting up crio"
echo "-------------------------------"

cat <<EOF | sudo tee /etc/modules-load.d/crio.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/ /" | tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/1.22/xUbuntu_20.04/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:1.22.list
wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:1.22/xUbuntu_20.04/Release.key -O- | apt-key add -
wget -nv https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/Release.key -O- | apt-key add -
apt-get update -qq 
apt-get install -y cri-o cri-o-runc

systemctl daemon-reload
systemctl restart crio
systemctl enable crio
