# Kubernetes Vagrant

This project brings up 3 Virtualbox VMs running Ubuntu 18.04 with `kubeadm` and dependencies installed plus instructions to set up you `kubernetes` multinode cluster (1 master + 2 workers).

It was upgraded and tested with *Kubernetes 1.18.5*, *Calico 3.14*, *Docker 19.03.12*, *Containerd 1.3.4* and *Cri-o 1.17*.

- [Kubernetes Vagrant](#kubernetes-vagrant)
  - [0. Install (or upgrade) dependencies](#0-install-or-upgrade-dependencies)
    - [Mac OS with homebrew (https://brew.sh/)](#mac-os-with-homebrew-httpsbrewsh)
    - [Windows with chocolatey](#windows-with-chocolatey)
    - [Linux, FreeBSD, OpenBSD, others](#linux-freebsd-openbsd-others)
    - [Install / Upgrade vagrant plugins](#install--upgrade-vagrant-plugins)
    - [The vagrant base box](#the-vagrant-base-box)
  - [1. Get this source code if you didn't yet](#1-get-this-source-code-if-you-didnt-yet)
  - [2. Set up the cluster](#2-set-up-the-cluster)
    - [Remove old config file](#remove-old-config-file)
    - [Bring machines up](#bring-machines-up)
    - [Reset cluster if created previously](#reset-cluster-if-created-previously)
    - [Initialise master node](#initialise-master-node)
    - [Set up network](#set-up-network)
    - [Join worker nodes](#join-worker-nodes)
  - [3. Setting up kubconfig](#3-setting-up-kubconfig)
    - [Get the new config file](#get-the-new-config-file)
    - [Point your `kubectl` to use it](#point-your-kubectl-to-use-it)
  - [4. Shut down or reset](#4-shut-down-or-reset)
  - [5. Bonus tips (Optional)](#5-bonus-tips-optional)
    - [Set up local hosts file](#set-up-local-hosts-file)
    - [Mixing up runtimes](#mixing-up-runtimes)

## 0. Install (or upgrade) dependencies

Install Virtualbox, Vagrant and kubernetes cli.

### Mac OS with homebrew (https://brew.sh/)

```bash
brew upgrade --cask virtualbox vagrant
brew upgrade kubernetes-cli
```

or

```bash
brew install --cask virtualbox vagrant
brew install kubernetes-cli
```

### Windows with chocolatey

```bash
choco upgrade virtualbox vagrant kubernetes-cli
```
 
or

```bash
choco install virtualbox vagrant kubernetes-cli
```

### Linux, FreeBSD, OpenBSD, others

You may know what to do. Here follow some links to help:

- https://www.virtualbox.org/wiki/Downloads
- https://www.vagrantup.com/downloads.html
- https://kubernetes.io/docs/tasks/tools/install-kubectl/

### Install / Upgrade vagrant plugins

```bash
$ vagrant plugin install vagrant-vbguest vagrant-cachier
$ vagrant plugin update vagrant-vbguest vagrant-cachier
```

### The vagrant base box

Install or update the Vagrant box

For Docker containers:

```bash
vagrant box add wsilva/k8s-docker --provider virtualbox
```

For Containerd containers:

```bash
vagrant box add wsilva/k8s-containerd --provider virtualbox
```

For Cri-o containers:

```bash
vagrant box add wsilva/k8s-crio --provider virtualbox
```

It takes arround 20 minutes in a 300Mpbs internet connection.

>To build the box images manually checkout [here](packer/README-enUS.md) how to do it.

## 1. Get this source code if you didn't yet

First we need to clone the project:

```bash
git clone https://github.com/wsilva/kubernetes-vagrant
cd kubernetes-vagrant
```

## 2. Set up the cluster

### Remove old config file

Removes previous generated config file if exists

```bash
rm -f ./kubernetes-vagrant-config
```

### Bring machines up

Bring machines up and/or reprovision it takes little less than 10 minutes in the first time.

For Docker:

```bash
vagrant up --provision
```

For Containerd:

```bash
export RUNTIME=containerd
$Env:RUNTIME = "containerd"
vagrant up --provision
```

For Cri-o:

```bash
export RUNTIME=crio
$Env:RUNTIME = "crio"
vagrant up --provision
```

### Reset cluster if created previously

```bash
vagrant ssh k8smaster -c "sudo kubeadm reset --force" && \
vagrant ssh k8snode1 -c "sudo kubeadm reset --force" && \
vagrant ssh k8snode2 -c "sudo kubeadm reset --force"
```

### Initialise master node

For Docker:

```bash
vagrant ssh k8smaster -c \
"sudo kubeadm init --apiserver-advertise-address 192.168.7.10 --pod-network-cidr=172.16.0.0/16 --ignore-preflight-errors=Mem"
```

For  Containerd:

```bash
vagrant ssh k8smaster -c \
"sudo kubeadm init --cri-socket /run/containerd/containerd.sock --apiserver-advertise-address 192.168.7.10 --pod-network-cidr=172.16.0.0/16 --ignore-preflight-errors=Mem"
```

For Cri-o:

```bash
vagrant ssh k8smaster -c \
"sudo kubeadm init --cri-socket /var/run/crio/crio.sock --apiserver-advertise-address 192.168.7.10 --pod-network-cidr=172.16.0.0/16 --ignore-preflight-errors=Mem"
```

Create config path, file and set ownership inside master node

```bash
vagrant ssh k8smaster -c \
"mkdir -p /home/vagrant/.kube"

vagrant ssh k8smaster -c \
"sudo cp -rf /etc/kubernetes/admin.conf /home/vagrant/.kube/config"

vagrant ssh k8smaster -c \
"sudo chown vagrant:vagrant /home/vagrant/.kube/config"
```

### Set up network

Set up calico CNI for kubernetes

```bash
vagrant ssh k8smaster -c \
"kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml"
```

### Join worker nodes

Get token and public key from master node

```bash
export KUBEADMTOKEN=$(vagrant ssh k8smaster -- sudo kubeadm token list | grep init | awk '{print $1}')

export KUBEADMPUBKEY=$(vagrant ssh k8smaster -c "sudo openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'")
```

Join nodes on cluster.

For Docker:

```bash
vagrant ssh k8snode1 -c \
"sudo kubeadm join 192.168.7.10:6443 --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY}"

vagrant ssh k8snode2 -c \
"sudo kubeadm join 192.168.7.10:6443 --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY}"
```

For Containerd:

```bash
vagrant ssh k8snode1 -c \
"sudo kubeadm join 192.168.7.10:6443 --cri-socket /run/containerd/containerd.sock --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY}"

vagrant ssh k8snode2 -c \
"sudo kubeadm join 192.168.7.10:6443 --cri-socket /run/containerd/containerd.sock --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY}"
```

For Cri-o

```bash
vagrant ssh k8snode1 -c \
"sudo kubeadm join 192.168.7.10:6443 --cri-socket /var/run/crio/crio.sock --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY}"

vagrant ssh k8snode2 -c \
"sudo kubeadm join 192.168.7.10:6443 --cri-socket /var/run/crio/crio.sock --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY}"
```

## 3. Setting up kubconfig

### Get the new config file

Copy config file from master node to shared folder

```bash
vagrant ssh k8smaster -c \
"cp ~/.kube/config /vagrant/kubernetes-vagrant-config"

vagrant ssh k8smaster -c \
"sed -i 's/kubernetes-admin/k8s/g' /vagrant/kubernetes-vagrant-config"

vagrant ssh k8smaster -c \
"sed -i 's/kubernetes/vagrant/g' /vagrant/kubernetes-vagrant-config"
```

### Point your `kubectl` to use it

You can merge the generated `kubernetes-vagrant-config` file with your $HOME/.kube/config file. And redo it everytime o set up the cluster again.

Or you can just export the following env var to point to both config files:

```bash
export KUBECONFIG=$HOME/.kube/config:$PWD/kubernetes-vagrant-config
```

And then select the brand new vagrant kubernetes cluster created:

```bash
kubectl config use-context k8s@vagrant
```

## 4. Shut down or reset

For shutting it down we just need to `vagrant halt`.

When you need your cluster back just run `vagrant up` and wait.

In case of problem we can reprovision running [step 2](#2-set-up-the-cluster) and [step 3](#3-setting-up-kubconfig) again, it will be reprovisioned but way faster than the first time.

But if you are lazy like me you can run the following after regular `vagrant up`:

For Docker:

```bash
vagrant ssh k8smaster -c "sudo kubeadm reset --force" \
  && vagrant ssh k8snode1 -c "sudo kubeadm reset --force" \
  && vagrant ssh k8snode2 -c "sudo kubeadm reset --force" \
  && vagrant ssh k8smaster -c "sudo kubeadm init --apiserver-advertise-address 192.168.7.10 --pod-network-cidr=172.16.0.0/16" \
  && vagrant ssh k8smaster -c "mkdir -p /home/vagrant/.kube" \
  && vagrant ssh k8smaster -c "sudo cp -rf /etc/kubernetes/admin.conf /home/vagrant/.kube/config" \
  && vagrant ssh k8smaster -c "sudo chown vagrant:vagrant /home/vagrant/.kube/config" \
  && vagrant ssh k8smaster -c "kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml" \
  && export KUBEADMTOKEN=$(vagrant ssh k8smaster -- sudo kubeadm token list | grep init | awk '{print $1}') \
  && export KUBEADMPUBKEY=$(vagrant ssh k8smaster -c "sudo openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'") \
  && vagrant ssh k8snode1 -c "sudo kubeadm join 192.168.7.10:6443 --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY}" \
  && vagrant ssh k8snode2 -c "sudo kubeadm join 192.168.7.10:6443 --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY}" \
  && vagrant ssh k8smaster -c "cp ~/.kube/config /vagrant/kubernetes-vagrant-config" \
  && vagrant ssh k8smaster -c "sed -i 's/kubernetes-admin/k8s/g' /vagrant/kubernetes-vagrant-config" \
  && vagrant ssh k8smaster -c "sed -i 's/kubernetes/vagrant/g' /vagrant/kubernetes-vagrant-config" \
  && export KUBECONFIG=$HOME/.kube/config:$PWD/kubernetes-vagrant-config \
  && kubectl config use-context k8s@vagrant
```

For Containerd:

```bash
vagrant ssh k8smaster -c "sudo kubeadm reset --force" \
  && vagrant ssh k8snode1 -c "sudo kubeadm reset --force" \
  && vagrant ssh k8snode2 -c "sudo kubeadm reset --force" \
  && vagrant ssh k8smaster -c "sudo kubeadm init --cri-socket /run/containerd/containerd.sock --apiserver-advertise-address 192.168.7.10 --pod-network-cidr=172.16.0.0/16" \
  && vagrant ssh k8smaster -c "mkdir -p /home/vagrant/.kube" \
  && vagrant ssh k8smaster -c "sudo cp -rf /etc/kubernetes/admin.conf /home/vagrant/.kube/config" \
  && vagrant ssh k8smaster -c "sudo chown vagrant:vagrant /home/vagrant/.kube/config" \
  && vagrant ssh k8smaster -c "kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml" \
  && export KUBEADMTOKEN=$(vagrant ssh k8smaster -- sudo kubeadm token list | grep init | awk '{print $1}') \
  && export KUBEADMPUBKEY=$(vagrant ssh k8smaster -c "sudo openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'") \
  && vagrant ssh k8snode1 -c "sudo kubeadm join 192.168.7.10:6443 --cri-socket /run/containerd/containerd.sock --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY}" \
  && vagrant ssh k8snode2 -c "sudo kubeadm join 192.168.7.10:6443 --cri-socket /run/containerd/containerd.sock --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY}" \
  && vagrant ssh k8smaster -c "cp ~/.kube/config /vagrant/kubernetes-vagrant-config" \
  && vagrant ssh k8smaster -c "sed -i 's/kubernetes-admin/k8s/g' /vagrant/kubernetes-vagrant-config" \
  && vagrant ssh k8smaster -c "sed -i 's/kubernetes/vagrant/g' /vagrant/kubernetes-vagrant-config" \
  && export KUBECONFIG=$HOME/.kube/config:$PWD/kubernetes-vagrant-config \
  && kubectl config use-context k8s@vagrant
```

For Cri-o:

```bash
vagrant ssh k8smaster -c "sudo kubeadm reset --force" \
  && vagrant ssh k8snode1 -c "sudo kubeadm reset --force" \
  && vagrant ssh k8snode2 -c "sudo kubeadm reset --force" \
  && vagrant ssh k8smaster -c "sudo kubeadm init --cri-socket /var/run/crio/crio.sock --apiserver-advertise-address 192.168.7.10 --pod-network-cidr=172.16.0.0/16" \
  && vagrant ssh k8smaster -c "mkdir -p /home/vagrant/.kube" \
  && vagrant ssh k8smaster -c "sudo cp -rf /etc/kubernetes/admin.conf /home/vagrant/.kube/config" \
  && vagrant ssh k8smaster -c "sudo chown vagrant:vagrant /home/vagrant/.kube/config" \
  && vagrant ssh k8smaster -c "kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml" \
  && export KUBEADMTOKEN=$(vagrant ssh k8smaster -- sudo kubeadm token list | grep init | awk '{print $1}') \
  && export KUBEADMPUBKEY=$(vagrant ssh k8smaster -c "sudo openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'") \
  && vagrant ssh k8snode1 -c "sudo kubeadm join 192.168.7.10:6443 --cri-socket /var/run/crio/crio.sock --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY}" \
  && vagrant ssh k8snode2 -c "sudo kubeadm join 192.168.7.10:6443 --cri-socket /var/run/crio/crio.sock --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY}" \
  && vagrant ssh k8smaster -c "cp ~/.kube/config /vagrant/kubernetes-vagrant-config" \
  && vagrant ssh k8smaster -c "sed -i 's/kubernetes-admin/k8s/g' /vagrant/kubernetes-vagrant-config" \
  && vagrant ssh k8smaster -c "sed -i 's/kubernetes/vagrant/g' /vagrant/kubernetes-vagrant-config" \
  && export KUBECONFIG=$HOME/.kube/config:$PWD/kubernetes-vagrant-config \
  && kubectl config use-context k8s@vagrant
```

## 5. Bonus tips (Optional)

### Set up local hosts file

The machines have fixed ip addresses but we can set Mac OS and Linux hosts file to easily access virtual machines by it's names

```bash
echo "192.168.7.10 k8smaster.local k8smaster" | sudo tee -a /etc/hosts
echo "192.168.7.11 k8snode1.local k8snode1" | sudo tee -a /etc/hosts
echo "192.168.7.12 k8snode2.local k8snode2" | sudo tee -a /etc/hosts
```

In Windows you need to edit `C:\Windows\System32\drivers\etc\hosts` file as Administrator.

### Mixing up runtimes

To run different container runtimes:

```bash
export RUNTIME=containerd \
&& vagrant up k8smaster \
&& vagrant ssh k8smaster -c "sudo kubeadm init --apiserver-advertise-address 192.168.7.10 --pod-network-cidr=172.16.0.0/16 --cri-socket /run/containerd/containerd.sock --ignore-preflight-errors=Mem" \
&& vagrant ssh k8smaster -c "mkdir -p /home/vagrant/.kube" \
&& vagrant ssh k8smaster -c "sudo cp -rf /etc/kubernetes/admin.conf /home/vagrant/.kube/config" \
&& vagrant ssh k8smaster -c "sudo chown vagrant:vagrant /home/vagrant/.kube/config" \
&& vagrant ssh k8smaster -c "kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml" \
&& vagrant ssh k8smaster -c "cp ~/.kube/config /vagrant/kubernetes-vagrant-config" \
&& vagrant ssh k8smaster -c "sed -i 's/kubernetes-admin/k8s/g' /vagrant/kubernetes-vagrant-config" \
&& vagrant ssh k8smaster -c "sed -i 's/kubernetes/vagrant/g' /vagrant/kubernetes-vagrant-config" \
&& export KUBECONFIG=$HOME/.kube/config:$PWD/kubernetes-vagrant-config \
&& kubectl config use-context k8s@vagrant \
&& export RUNTIME=crio \
&& vagrant up k8snode1 \
&& export KUBEADMTOKEN=$(vagrant ssh k8smaster -- sudo kubeadm token list | grep init | awk '{print $1}') \
&& export KUBEADMPUBKEY=$(vagrant ssh k8smaster -c "sudo openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'") \
&& vagrant ssh k8snode1 -c "sudo kubeadm join 192.168.7.10:6443 --cri-socket /var/run/crio/crio.sock --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY}" \
&& export RUNTIME=docker \
&& vagrant up k8snode2 \
&& export KUBEADMTOKEN=$(vagrant ssh k8smaster -- sudo kubeadm token list | grep init | awk '{print $1}') \
&& export KUBEADMPUBKEY=$(vagrant ssh k8smaster -c "sudo openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'") \
&& vagrant ssh k8snode2 -c "sudo kubeadm join 192.168.7.10:6443 --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY}"
```
