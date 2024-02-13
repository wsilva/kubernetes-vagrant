#!/bin/bash

# Install containerd
echo "-------------------------------"
echo "Install containerd"
echo "-------------------------------"
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
sudo rm -f /usr/share/keyrings/docker-archive-keyring.gpg
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update && sudo apt-get install -y containerd.io

# Setup containerd
echo "-------------------------------"
echo "Setup containerd"
echo "-------------------------------"
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd

# Fix Kubelet config for Debian like machines to avoid issues while port forwarding or exec -it 
# and set up kubelet for containerd
echo "-------------------------------"
echo "set up kubelet for containerd"
echo "-------------------------------"
sudo mkdir -p /etc/systemd/system/kubelet.service.d/
echo "[Service]" | sudo tee /etc/systemd/system/kubelet.service.d/0-containerd.conf
echo "Environment=\"KUBELET_EXTRA_ARGS= --cgroup-driver=systemd --container-runtime-endpoint=unix:///run/containerd/containerd.sock --node-ip=$(ip addr | grep 192.168.7 | awk '{print $2}' | cut -d/ -f1)\"" | sudo tee -a /etc/systemd/system/kubelet.service.d/0-containerd.conf

# Download latest container images
echo "-------------------------------"
echo "Download latest container images"
echo "-------------------------------"
sudo kubeadm config images pull --cri-socket unix:///run/containerd/containerd.sock
