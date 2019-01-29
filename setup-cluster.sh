#!/bin/bash
set -x

rm -f ./kubernetes-vagrant-config

vagrant up --provision

vagrant ssh k8smaster -c "sudo kubeadm reset --force"

# calico
vagrant ssh k8smaster -c "sudo kubeadm config images pull"
vagrant ssh k8smaster -c "sudo kubeadm init --ignore-preflight-errors=SystemVerification --config=/vagrant/kubeadm-config.yaml"

# weave
# vagrant ssh k8smaster -c "sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --config=/vagrant/kubeadm-config.yaml"

vagrant ssh k8smaster -c "mkdir -p /home/vagrant/.kube"
vagrant ssh k8smaster -c "sudo cp -rf /etc/kubernetes/admin.conf /home/vagrant/.kube/config"
vagrant ssh k8smaster -c "sudo chown vagrant:vagrant /home/vagrant/.kube/config"

# calico with k8s version 1.11
vagrant ssh k8smaster -c "kubectl apply -f https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml"
vagrant ssh k8smaster -c "kubectl apply -f https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml"

# weave with k8s version 1.11
# vagrant ssh k8smaster -c "sudo sysctl net.bridge.bridge-nf-call-iptables=1"
# vagrant ssh k8smaster -c "kubectl apply -f \"https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')\""

vagrant ssh k8smaster -c "kubectl taint nodes --all node-role.kubernetes.io/master- "

JOINCMD=$(vagrant ssh k8smaster -c "sudo kubeadm token create --print-join-command")

vagrant ssh k8snode1 -c "sudo ${JOINCMD} --ignore-preflight-errors=SystemVerification "
vagrant ssh k8snode2 -c "sudo ${JOINCMD} --ignore-preflight-errors=SystemVerification "

vagrant ssh k8smaster -c "kubectl label node k8snode1 node-role.kubernetes.io/node="
vagrant ssh k8smaster -c "kubectl label node k8snode2 node-role.kubernetes.io/node="

vagrant ssh k8smaster -c "cp ~/.kube/config /vagrant/kubernetes-vagrant-config"

export KUBECONFIG=$HOME/.kube/config:./kubernetes-vagrant-config

