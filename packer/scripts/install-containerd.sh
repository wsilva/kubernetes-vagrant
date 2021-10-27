#!/bin/sh -eux

# Setup containerD 
echo "-------------------------------"
echo "Setting up containerd"
echo "-------------------------------"

cat <<EOF >/etc/modules-load.d/containerd.conf
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack_ipv4
ip_vs
overlay
br_netfilter
EOF
sysctl --system

# # Install via deb package
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
# add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update -qq
apt-get install -y containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
systemctl restart containerd
# echo "plugins.cri.systemd_cgroup = true" >> /etc/containerd/config.toml

# # Install manually
# apt-get install -y libseccomp2 btrfs-tools socat util-linux
# mkdir -p /opt/cni/bin/
# mkdir -p /etc/cni/net.d/
# mkdir -p /etc/containerd
# export VERSION="1.3.4"
# curl -fsSLO https://storage.googleapis.com/cri-containerd-release/cri-containerd-${VERSION}.linux-amd64.tar.gz
# tar --no-overwrite-dir -C / -xzf cri-containerd-${VERSION}.linux-amd64.tar.gz
# systemctl start containerd
# containerd config default > /etc/containerd/config.toml

# Reload / Restart
systemctl daemon-reload
systemctl restart containerd
systemctl enable containerd