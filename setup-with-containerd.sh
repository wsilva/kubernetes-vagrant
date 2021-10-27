#!/bin/bash

sed -i '/swap/d' /etc/fstab
swapoff -a

systemctl disable --now ufw >/dev/null 2>&1

cat >>/etc/modules-load.d/containerd.conf<<EOF
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system >/dev/null 2>&1

# set up hostname
echo "-------------------------------"
echo "Set up hostnames"
echo "-------------------------------"
cat >>/etc/hosts<<EOF
192.168.7.10 k8smaster.local k8smaster
192.168.7.11 k8snode1.local k8snode1
192.168.7.12 k8snode2.local k8snode2
EOF

# Fix Kubelet config for Debian like machines to avoid issues while port forwarding or exec -it 
# and set it up for containerd
echo "-------------------------------"
echo "set up kubelet for containerd"
echo "-------------------------------"
echo "[Service]" | tee /etc/systemd/system/kubelet.service.d/0-containerd.conf
echo "Environment=\"KUBELET_EXTRA_ARGS= --runtime-cgroups=/system.slice/containerd.service --container-runtime=remote --runtime-request-timeout=15m --container-runtime-endpoint=unix:///run/containerd/containerd.sock --node-ip=$(ip addr | grep 192.168.7 | awk '{print $2}' | cut -d/ -f1)\"" | tee -a /etc/systemd/system/kubelet.service.d/0-containerd.conf
