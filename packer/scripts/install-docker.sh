#!/bin/bash

# Install last stable Docker
echo "-------------------------------"
echo "Installing Docker"
echo "-------------------------------"
curl -fsSL https://get.docker.com | bash
usermod -aG docker vagrant

# Change Docker cgroups driver from standard cgroupsfs to systemd - the check command: docker info | grep 'Cgroup Driver'
# link to the issue: https://github.com/kubernetes/kubeadm/issues/1218
echo "-------------------------------"
echo "Change Docker cgroups driver from standard cgroupsfs to systemd"
echo "-------------------------------"
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
systemctl daemon-reload
systemctl restart docker
systemctl enable docker
