#!/bin/bash

# Install kubernetes
echo "-------------------------------"
echo "Installing kubelet, kubeadm, kubeclt, etc"
echo "-------------------------------"
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
apt-get update -qq
apt install -y -q kubelet kubeadm kubectl

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
