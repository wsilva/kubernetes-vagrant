
# Kubernetes Vagrant

This project brings up 3 Virtualbox VMs running Ubuntu 16.04. Then we install *kubeadm* and it's dependencies on version 1.11.3 (1.12 are still breaking somethings). The *Calico* CNI will be set up for networking.

To use *Weave* CNI instead of *Calico* just invert the comments in ```setup-cluster.sh```, where it mention calico we comment and where it mention weave just uncomment.


## 0. Install (or upgrade) dependencies

Install Virtualbox, Vagrant, vagrant-cachier and vagrant-vbguest plugins for vagrant and kubernetes cli.


### OSX with homebrew (https://brew.sh/)

~~~bash
brew cask install virtualbox
brew cask install vagrant
brew install kubernetes-cli
~~~

### Windows with chocolatey

~~~bash
choco install virtualbox
choco install vagrant
choco install kubernetes-cli
~~~

### Linux, FreeBSD, OpenBSD, others

You may know what to do. Here follow some links to help:
 - https://www.virtualbox.org/wiki/Downloads
 - https://www.vagrantup.com/downloads.html
 - https://kubernetes.io/docs/tasks/tools/install-kubectl/

### Vagrant plugins

Install one at a time, installing both at once cause version/dependency conflict.

~~~bash
vagrant plugin install vagrant-cachier
vagrant plugin install vagrant-vbguest
~~~

### The vagrant base box

```bash
vagrant box add ubuntu/bionic64
```

```bash
vagrant box update ubuntu/bionic64
```


## 1. Get the source

First we need to clone the project:

~~~bash
git clone https://github.com/wsilva/kubernetes-vagrant
cd kubernetes-vagrant
~~~


## 2. Set up the cluster

Remove old config file

```bash
rm -f ./kubernetes-vagrant-config
```

Bring machines up and/or reprovision

```bash
vagrant up k8smaster --provision
```

```bash
vagrant up k8snode1 --provision
```

```bash
vagrant up k8snode2 --provision
```

Reset if there is an old cluster

```bash
vagrant ssh k8smaster -c "sudo kubeadm reset --force"
```

Initialise master node

```bash
vagrant ssh k8smaster -c "sudo kubeadm init --apiserver-advertise-address 192.168.7.10 --pod-network-cidr=192.168.0.0/16"
```

Create config path, file and set ownership inside master node

```bash
vagrant ssh k8smaster -c "mkdir -p /home/vagrant/.kube"
vagrant ssh k8smaster -c "sudo cp -rf /etc/kubernetes/admin.conf /home/vagrant/.kube/config"
vagrant ssh k8smaster -c "sudo chown vagrant:vagrant /home/vagrant/.kube/config"
```

Set up calico CNI for `kubernetes 1.15` version

```bash
vagrant ssh k8smaster -c "kubectl apply -f https://docs.projectcalico.org/v3.8/manifests/calico.yaml"
```

If you want to run regular pods on master node, not recomended

```bash
vagrant ssh k8smaster -c "kubectl taint nodes --all node-role.kubernetes.io/master- "
```

Get token and public key from master node

```bash
KUBEADMTOKEN=$(vagrant ssh k8smaster -- sudo kubeadm token list | grep init | awk '{print $1}')
```

```bash
KUBEADMPUBKEY=$(vagrant ssh k8smaster -c "sudo openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'")
```

Join nodes on cluster
```bash
vagrant ssh k8snode1 -c "sudo kubeadm join 192.168.7.10:6443 --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY}"
```

```bash
vagrant ssh k8snode2 -c "sudo kubeadm join 192.168.7.10:6443 --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY}"
```

Label them as node

```bash
vagrant ssh k8smaster -c "kubectl label node k8snode1 node-role.kubernetes.io/node="
```

```bash
vagrant ssh k8smaster -c "kubectl label node k8snode2 node-role.kubernetes.io/node="
```

Copy config file from master node to shared folder

```bash
vagrant ssh k8smaster -c "cp ~/.kube/config /vagrant/kubernetes-vagrant-config"
```

## 3. Setting up kubconfig

You can merge the generated ```kubernetes-vagrant-config``` file with your $HOME/.kube/config file. And redo it everytime o set up the cluster again.

Or you can just export the following env var to point to both config files:

~~~bash
export KUBECONFIG=$HOME/.kube/config:kubernetes-vagrant-config
~~~

And then select the brand new vagrant kubernetes cluster created:

~~~bash
kubectl config use-context kubernetes-admin@k8s-vagrant
~~~

## 4. Shut down or reset

For shutting it down we just need to ```vagrant halt```. 
When you need your cluster back just run step 2 again, it will be reprovisioned but way faster than the first time.
