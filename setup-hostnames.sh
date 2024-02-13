#!/bin/bash

# set up hostname
echo "-------------------------------"
echo "Set up hostnames"
echo "-------------------------------"
grep k8smaster /etc/hosts
if [[ $? -ne 0 ]]; then
    echo "Populating /etc/hosts."
    cat >>/etc/hosts<<EOF
192.168.7.10 k8smaster.local k8smaster
192.168.7.11 k8snode1.local k8snode1
192.168.7.12 k8snode2.local k8snode2
EOF
else
    echo "File /etc/hosts already populated"
fi