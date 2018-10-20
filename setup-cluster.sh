#!/bin/bash
set -x

vagrant up --provision

JOINCMD=$(vagrant ssh k8smaster -c "sudo kubeadm token create --print-join-command")

vagrant ssh k8snode2 -c "sudo ${JOINCMD}"
vagrant ssh k8snode3 -c "sudo ${JOINCMD}"

vagrant ssh k8smaster -c "cp ~/.kube/config /vagrant/kubernetes-vagrant-config"

export  KUBECONFIG=$KUBECONFIG:kubernetes-vagrant-config

