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
sysctl net.bridge.bridge-nf-call-ip6tables=1
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

# Install last stable Docker
echo "-------------------------------"
echo "Installing Docker"
echo "-------------------------------"
docker version
if [ "$?" -ne 0 ]
then
    curl -fsSL https://get.docker.com | bash
fi
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

# Fix Kubelet config for Debian like machines to avoid issues while port forwarding or exec -it
echo "-------------------------------"
echo "Create custom kubelet config file"
echo "-------------------------------"
echo "KUBELET_EXTRA_ARGS=\"--node-ip=$(ifconfig | grep 192.168.7 | awk '{print $2}')\"" | tee /etc/default/kubelet
