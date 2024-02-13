#!/bin/bash

# Install K8s packages
export K8S_VERSION=$1
echo "-------------------------------"
echo "Install K8s packages"
echo "-------------------------------"
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update && sudo apt-get install -y kubeadm kubelet kubectl

# Hold k8s packages version
echo "-------------------------------"
echo "Hold k8s packages version"
echo "-------------------------------"
sudo apt-mark hold kubelet kubeadm kubectl

# Set up bash completion
echo "-------------------------------"
echo "Set up bash completion"
echo "-------------------------------"
kubeadm completion bash > /etc/bash_completion.d/kubeadm
kubectl completion bash > /etc/bash_completion.d/kubectl
