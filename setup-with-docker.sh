#!/bin/bash


# Install last stable Docker
echo "-------------------------------"
echo "Installing Docker"
echo "-------------------------------"
sudo rm -f /etc/apt/keyrings/docker.gpg
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update -qq
sudo apt-get install -y docker-ce docker-ce-cli


# Change Docker cgroups driver from standard cgroupsfs to systemd - the check command: docker info | grep 'Cgroup Driver'
# link to the issue: https://github.com/kubernetes/kubeadm/issues/1218
echo "-------------------------------"
echo "Change Docker cgroups driver from standard cgroupsfs to systemd"
echo "-------------------------------"
sudo mkdir -p /etc/docker
cat <<EOF >/etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
mkdir -p /etc/systemd/system/docker.service.d
usermod -aG docker vagrant
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker


# Install and setup cri-dockerd
echo "-------------------------------"
echo "Install and setup cri-dockerd"
echo "-------------------------------"
curl -fsSLO https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.9/cri-dockerd_0.3.9.3-0.ubuntu-jammy_amd64.deb
sudo apt install -y ./cri-dockerd_0.3.9.3-0.ubuntu-jammy_amd64.deb
sudo systemctl daemon-reload
sudo systemctl enable --now cri-docker.socket


# Fix Kubelet config for Debian like machines to avoid issues while port forwarding or exec -it
# and set up kubelet for dockerd
echo "-------------------------------"
echo "Set up kubelet for dockerd"
echo "-------------------------------"
sudo mkdir -p /etc/systemd/system/kubelet.service.d/
echo "[Service]" | sudo tee /etc/systemd/system/kubelet.service.d/0-docker.conf
echo "Environment=\"KUBELET_EXTRA_ARGS= --cgroup-driver=systemd --container-runtime-endpoint=unix:///var/run/cri-dockerd.sock --node-ip=$(ip addr | grep 192.168.7 | awk '{print $2}' | cut -d/ -f1)\"" | sudo tee -a /etc/systemd/system/kubelet.service.d/0-docker.conf


# Download latest container images
echo "-------------------------------"
echo "Download latest container images"
echo "-------------------------------"
sudo kubeadm config images pull --cri-socket unix:///var/run/cri-dockerd.sock
