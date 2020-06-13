#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# apt stuff
echo "-------------------------------"
echo "Updating stuff APT"
echo "-------------------------------"
apt-get update
apt-get upgrade -y
apt-get install apt-transport-https bash-completion htop 

# Allow for network forwarding in IP Tables
echo "-------------------------------"
echo "Allow for network forwarding in IP Tables"
echo "-------------------------------"
modprobe br_netfilter
sysctl net.bridge.bridge-nf-call-iptables=1
echo 1 > /proc/sys/net/ipv4/ip_forward

# kubernetes requires swap off
echo "-------------------------------"
echo "Turning the swap off"
echo "-------------------------------"
swapoff -a
# keep swap off after reboot
cat /etc/fstab | grep '^[#]' | grep swap
if [ "$?" -ne 0 ]
then
    sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
fi

# Setup containerD 
echo "-------------------------------"
echo "Setting up containerD"
echo "-------------------------------"
cat <<EOF >/etc/modules-load.d/k8s.conf
br_netfilter
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack_ipv4
ip_vs
EOF
cat <<EOF >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward=1
EOF
apt-get install -y libseccomp2 btrfs-tools socat util-linux
mkdir -p /opt/cni/bin/
mkdir -p /etc/cni/net.d/
mkdir -p /etc/containerd
VERSION="1.3.4"
curl -fsSLO https://storage.googleapis.com/cri-containerd-release/cri-containerd-${VERSION}.linux-amd64.tar.gz
tar --no-overwrite-dir -C / -xzf cri-containerd-${VERSION}.linux-amd64.tar.gz
systemctl start containerd
containerd config default > /etc/containerd/config.toml
systemctl daemon-reload
systemctl restart containerd

# Install kubernetes
echo "-------------------------------"
echo "Installing kubelet, kubeadm, kubeclt, etc"
echo "-------------------------------"
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
export APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
unset APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE
kubeadm version
if [ "$?" -ne 0 ]
then
    apt-get update && apt-get install -y kubelet kubeadm kubectl
fi

# Fix Kubelet config for Debian like machines to avoid issues while port forwarding or exec -it and set it up for containerd
echo "-------------------------------"
echo "set up kubelet for containerd"
echo "-------------------------------"
echo "[Service]" > /etc/systemd/system/kubelet.service.d/0-containerd.conf
echo "Environment=\"KUBELET_EXTRA_ARGS= --runtime-cgroups=/system.slice/containerd.service --container-runtime=remote --runtime-request-timeout=15m --container-runtime-endpoint=unix:///run/containerd/containerd.sock --node-ip=$(ifconfig | grep 192.168.7 | awk '{print $2}')\"" >> /etc/systemd/system/kubelet.service.d/0-containerd.conf

# reset if something is already defined
echo "-------------------------------"
echo "Reset Kubeadm if it is already set"
echo "-------------------------------"
echo "Reset kubeadm"
kubeadm reset --force

# set up completion
echo "-------------------------------"
echo "Set up bash completion"
echo "-------------------------------"
kubeadm completion bash > /etc/bash_completion.d/kubeadm
kubectl completion bash > /etc/bash_completion.d/kubectl

# Download latest container images
echo "-------------------------------"
echo "Downloading k8s container images"
echo "-------------------------------"
kubeadm config images pull 
