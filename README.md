
# Kubernetes Vagrant

This project brings up 3 Virtualbox VMs running Ubuntu 16.04. Then we install *kubeadm* and it's dependencies on version 1.11.3 (1.12 are still breaking somethings). The *Calico* CNI will be set up for networking.

To use *Weave* CNI instead of *Calico* just invert the comments in ```setup-cluster.sh```, where it mention calico we comment and where it mention weave just uncomment.


## 0. Install dependencies

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
You may know what to do. 
Links:
 - https://www.virtualbox.org/wiki/Downloads
 - https://www.vagrantup.com/downloads.html
 - https://kubernetes.io/docs/tasks/tools/install-kubectl/

### Vagrant plugins

~~~bash
vagrant plugin install vagrant-cachier vagrant-vbguest
~~~


## 1. Get the source

First we need to clone the project:

~~~bash
git clone https://github.com/wsilva/kubernetes-vagrant
cd kubernetes-vagrant
~~~


## 2. Set up the cluster

Just run the following shell script file or if you want just run each command and follow it

~~~bash
./setup-cluster.sh
~~~

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
When you need your cluster back just ```./setup-cluster.sh``` again, it will be reprovisioned but way faster than the first time.
