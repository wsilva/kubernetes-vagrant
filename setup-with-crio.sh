#!/bin/bash

# Setup cri-o
echo "-------------------------------"
echo "Setting up crio"
echo "-------------------------------"

export K8S_VERSION=$1
curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/stable:/v${K8S_VERSION}:/build/deb/Release.key | gpg --dearmor --yes -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://download.opensuse.org/repositories/isv:/kubernetes:/addons:/cri-o:/stable:/v${K8S_VERSION}:/build/deb/ /" | sudo tee /etc/apt/sources.list.d/cri-o.list

# sudo apt-get update -qq && apt-get install -y cri-o cri-o-runc
sudo apt-get update -qq && apt-get install -y cri-o
sudo systemctl daemon-reload
sudo systemctl restart crio
sudo systemctl enable crio

# Fix Kubelet config for Debian like machines to avoid issues while port forwarding or exec -it 
# and set up kubelet for crio
echo "-------------------------------"
echo "Set up kubelet for crio"
echo "-------------------------------"
sudo mkdir -p /etc/systemd/system/kubelet.service.d/
echo "[Service]" | sudo tee /etc/systemd/system/kubelet.service.d/0-crio.conf
echo "Environment=\"KUBELET_EXTRA_ARGS= --cgroup-driver=systemd --container-runtime-endpoint=unix:///var/run/crio/crio.sock --node-ip=$(ip addr | grep 192.168.7 | awk '{print $2}' | cut -d/ -f1)\"" | sudo tee -a /etc/systemd/system/kubelet.service.d/0-crio.conf


# Download latest container images
echo "-------------------------------"
echo "Download latest container images"
echo "-------------------------------"
sudo kubeadm config images pull  --cri-socket unix:///var/run/crio/crio.sock
