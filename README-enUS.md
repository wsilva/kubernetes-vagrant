- [Kubernetes Vagrant](#kubernetes-vagrant)
- [Install (or upgrade) dependencies](#install--or-upgrade--dependencies)
  * [OSX with homebrew (https://brew.sh/)](#osx-with-homebrew--https---brewsh--)
  * [Windows with chocolatey](#windows-with-chocolatey)
  * [Linux, FreeBSD, OpenBSD, others](#linux--freebsd--openbsd--others)
  * [Vagrant plugins](#vagrant-plugins)
  * [The vagrant base box](#the-vagrant-base-box)
- [Get this source code if you didn't yet](#get-this-source-code-if-you-didn-t-yet)
- [Set up the cluster](#set-up-the-cluster)
  * [Remove old config file](#remove-old-config-file)
  * [Bring machines up](#bring-machines-up)
  * [Reset cluster if created previously](#reset-cluster-if-created-previously)
  * [Initialise master node](#initialise-master-node)
  * [Set up network](#set-up-network)
  * [Join worker nodes](#join-worker-nodes)
- [Setting up kubconfig](#setting-up-kubconfig)
  * [Get the new config file](#get-the-new-config-file)
  * [Point your `kubectl` to use it](#point-your--kubectl--to-use-it)
- [Shut down or reset](#shut-down-or-reset)

# Kubernetes Vagrant

This project brings up 3 Virtualbox VMs running Ubuntu 18.04 with `kubeadm` and dependencies installed plus instructions to set up you `kubernetes` multinode cluster (1 master + 2 workers). 

It was upgraded and tested with Kubernetes 1+15, Calico 3.8 and Docker 19.03.

# Install (or upgrade) dependencies

Install Virtualbox, Vagrant, vagrant-cachier and vagrant-vbguest plugins for vagrant and kubernetes cli.

## OSX with homebrew (https://brew.sh/)

~~~bash
brew cask upgrade virtualbox vagrant
brew upgrade kubernetes-cli
~~~

or

~~~bash
brew cask install virtualbox vagrant
brew install kubernetes-cli
~~~

## Windows with chocolatey

~~~bash
choco upgrade virtualbox vagrant kubernetes-cli
~~~

~~~bash
choco install virtualbox vagrant kubernetes-cli
~~~

## Linux, FreeBSD, OpenBSD, others

You may know what to do. Here follow some links to help:
 - https://www.virtualbox.org/wiki/Downloads
 - https://www.vagrantup.com/downloads.html
 - https://kubernetes.io/docs/tasks/tools/install-kubectl/

## Vagrant plugins

Install one at a time, installing both at once cause version dependency conflict.

~~~bash
vagrant plugin install vagrant-cachier
vagrant plugin install vagrant-vbguest
~~~

## The vagrant base box

Install or update the ubuntu 18.04 box

```bash
vagrant box add ubuntu/bionic64
```

```bash
vagrant box update ubuntu/bionic64
```

It took arround 16 minutes.

# Get this source code if you didn't yet

First we need to clone the project:

~~~bash
git clone https://github.com/wsilva/kubernetes-vagrant
cd kubernetes-vagrant
~~~


# Set up the cluster

## Remove old config file

Removes previous generated config file

```bash
rm -f ./kubernetes-vagrant-config
```

## Bring machines up

Bring machines up and/or reprovision it takes arround 19 minutes in a average home internet connection. 

```bash
vagrant up --provision
```

\* If you want to bring up each machine individually you can run:

```bash
vagrant up k8smaster --provision; vagrant up k8snode1 --provision; vagrant up k8snode2 --provision
```

But don't do it in parallel because you can face issues due to the vagrant apt cache is not available yet. To provision all machines in parallel you can use one shell session for each and you must disable the usage of `vagrant-cachier plugin`. For it just comment the ```if Vagrant.has_plugin?("vagrant-cachier")``` and the correspondent ```end``` on `Vagrantfile`.

## Reset cluster if created previously

```bash
vagrant ssh k8smaster -c "sudo kubeadm reset --force"
```

## Initialise master node

```bash
vagrant ssh k8smaster -c "sudo kubeadm init --apiserver-advertise-address 192.168.7.10 --pod-network-cidr=192.168.0.0/16"
```

Create config path, file and set ownership inside master node

```bash
vagrant ssh k8smaster -c "mkdir -p /home/vagrant/.kube"
```

```bash
vagrant ssh k8smaster -c "sudo cp -rf /etc/kubernetes/admin.conf /home/vagrant/.kube/config"
```

```bash
vagrant ssh k8smaster -c "sudo chown vagrant:vagrant /home/vagrant/.kube/config"
```

## Set up network

Set up calico CNI for kubernetes version 1.15

```bash
vagrant ssh k8smaster -c "kubectl apply -f https://docs.projectcalico.org/v3.8/manifests/calico.yaml"
```

If you want to run regular pods on master node, not recomended

```bash
vagrant ssh k8smaster -c "kubectl taint nodes --all node-role.kubernetes.io/master- "
```

## Join worker nodes

Get token and public key from master node

```bash
export KUBEADMTOKEN=$(vagrant ssh k8smaster -- sudo kubeadm token list | grep init | awk '{print $1}')
```

```bash
export KUBEADMPUBKEY=$(vagrant ssh k8smaster -c "sudo openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'")
```

Join nodes on cluster
```bash
vagrant ssh k8snode1 -c "sudo kubeadm join 192.168.7.10:6443 --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY}"
```

```bash
vagrant ssh k8snode2 -c "sudo kubeadm join 192.168.7.10:6443 --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY}"
```

Label them as node (optional)

```bash
vagrant ssh k8smaster -c "kubectl label node k8snode1 node-role.kubernetes.io/node="
```

```bash
vagrant ssh k8smaster -c "kubectl label node k8snode2 node-role.kubernetes.io/node="
```


# Setting up kubconfig

## Get the new config file
Copy config file from master node to shared folder

```bash
vagrant ssh k8smaster -c "cp ~/.kube/config /vagrant/kubernetes-vagrant-config"
```

```bash
vagrant ssh k8smaster -c "sed -i 's/kubernetes-admin/k8s/g' /vagrant/kubernetes-vagrant-config"
```

```bash
vagrant ssh k8smaster -c "sed -i 's/kubernetes/vagrant/g' /vagrant/kubernetes-vagrant-config"
```

## Point your `kubectl` to use it

You can merge the generated ```kubernetes-vagrant-config``` file with your $HOME/.kube/config file. And redo it everytime o set up the cluster again.

Or you can just export the following env var to point to both config files:

~~~bash
export KUBECONFIG=$HOME/.kube/config:kubernetes-vagrant-config
~~~

And then select the brand new vagrant kubernetes cluster created:

~~~bash
kubectl config use-context k8s@vagrant
~~~

# Shut down or reset

For shutting it down we just need to ```vagrant halt```. 

When you need your cluster back just run [step 2](#2-set-up-the-cluster) again, it will be reprovisioned but way faster than the first time.
