#!/bin/sh -eux

# Install last stable Docker
echo "-------------------------------"
echo "Installing Docker"
echo "-------------------------------"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key --keyring /etc/apt/trusted.gpg.d/docker.gpg add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update -qq
# apt-get install -y docker-ce=5:19.03.11~3-0~ubuntu-$(lsb_release -cs) docker-ce-cli=5:19.03.11~3-0~ubuntu-$(lsb_release -cs)
apt-get install -y docker-ce docker-ce-cli


# Change Docker cgroups driver from standard cgroupsfs to systemd - the check command: docker info | grep 'Cgroup Driver'
# link to the issue: https://github.com/kubernetes/kubeadm/issues/1218
echo "-------------------------------"
echo "Change Docker cgroups driver from standard cgroupsfs to systemd"
echo "-------------------------------"
mkdir -p /etc/docker
cat <<EOF >/etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
mkdir -p /etc/systemd/system/docker.service.d
usermod -aG docker vagrant
systemctl daemon-reload
systemctl restart docker
systemctl enable docker
