#!/bin/bash
set -x

# remove old config 
rm -f ./kubernetes-vagrant-config

# up and reprovision
vagrant up --provision

# reset if there is an old cluster
vagrant ssh k8smaster -c "sudo kubeadm reset --force"

# calico
vagrant ssh k8smaster -c "sudo kubeadm init --apiserver-advertise-address 77.77.77.10 --pod-network-cidr=192.168.0.0/16"

# weave
# vagrant ssh k8smaster -c "sudo kubeadm init --apiserver-advertise-address 77.77.77.10"

# create config path, file and set ownership
vagrant ssh k8smaster -c "mkdir -p /home/vagrant/.kube"
vagrant ssh k8smaster -c "sudo cp -rf /etc/kubernetes/admin.conf /home/vagrant/.kube/config"
vagrant ssh k8smaster -c "sudo chown vagrant:vagrant /home/vagrant/.kube/config"

# calico
vagrant ssh k8smaster -c "kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml"
vagrant ssh k8smaster -c "kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml"

# weave
# vagrant ssh k8smaster -c "sudo sysctl net.bridge.bridge-nf-call-iptables=1"
# vagrant ssh k8smaster -c "kubectl apply -f \"https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')\""

# allow pods on master master
# vagrant ssh k8smaster -c "kubectl taint nodes --all node-role.kubernetes.io/master- "

# access just with token without pub key
# vagrant ssh k8snode1 -c "sudo kubeadm join 77.77.77.10:6443 --discovery-token-unsafe-skip-ca-verification --token=`sudo kubeadm token list`"
# vagrant ssh k8snode2 -c "sudo kubeadm join 77.77.77.10:6443 --discovery-token-unsafe-skip-ca-verification --token=`sudo kubeadm token list`"

# or get token and public key from master node
KUBEADMTOKEN=$(vagrant ssh k8smaster -- sudo kubeadm token list | grep init | awk '{print $1}')
KUBEADMPUBKEY=$(vagrant ssh k8smaster -c "sudo openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'")

# join nodes on cluster
vagrant ssh k8snode1 -c "sudo kubeadm join 77.77.77.10:6443 --token $KUBEADMTOKEN --discovery-token-ca-cert-hash sha256:$KUBEADMPUBKEY"
vagrant ssh k8snode2 -c "sudo kubeadm join 77.77.77.10:6443 --token $KUBEADMTOKEN --discovery-token-ca-cert-hash sha256:$KUBEADMPUBKEY"

# label them as node
vagrant ssh k8smaster -c "kubectl label node k8snode1 node-role.kubernetes.io/node="
vagrant ssh k8smaster -c "kubectl label node k8snode2 node-role.kubernetes.io/node="

# copy config from master node to local machine
vagrant ssh k8smaster -c "cp ~/.kube/config /vagrant/kubernetes-vagrant-config"

# try to export it to be used from host machine
export KUBECONFIG=$HOME/.kube/config:./kubernetes-vagrant-config

