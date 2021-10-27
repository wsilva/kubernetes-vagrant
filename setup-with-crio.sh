#!/bin/bash

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
# and set it up for crio
echo "-------------------------------"
echo "set up kubelet for crio"
echo "-------------------------------"
echo "[Service]" | tee /etc/systemd/system/kubelet.service.d/0-crio.conf
echo "Environment=\"KUBELET_EXTRA_ARGS= --cgroup-driver=systemd --container-runtime=remote --container-runtime-endpoint=unix:///var/run/crio/crio.sock --node-ip=$(ip addr | grep 192.168.7 | awk '{print $2}' | cut -d/ -f1)\"" | tee -a /etc/systemd/system/kubelet.service.d/0-crio.conf
