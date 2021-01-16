#!/bin/sh -eux

# Setup cri-o
echo "-------------------------------"
echo "Setting up crio"
echo "-------------------------------"

cat <<EOF >/etc/modules-load.d/crio.conf
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack_ipv4
ip_vs
overlay
br_netfilter
EOF
sysctl --system

echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/ /" | tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/1.20/xUbuntu_20.04/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:1.20.list
wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:1.20/xUbuntu_20.04/Release.key -O- | apt-key add -
wget -nv https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/Release.key -O- | apt-key add -
apt-get update -qq 
apt-get install -y cri-o cri-o-runc
systemctl daemon-reload
systemctl restart crio
systemctl enable crio
