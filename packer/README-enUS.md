# 0. Install (or upgrade) dependencies

## OSX with homebrew (https://brew.sh/)

~~~bash
brew cask upgrade virtualbox vagrant packer
~~~

or

~~~bash
brew cask install virtualbox vagrant packer
~~~

## Windows with chocolatey

~~~bash
choco upgrade virtualbox vagrant packer
~~~

or

~~~bash
choco install virtualbox vagrant packer
~~~

## Linux, FreeBSD, OpenBSD, and others

You may know what to do. Here follow some links to help:

- https://www.virtualbox.org/wiki/Downloads
- https://www.vagrantup.com/downloads.html
- https://learn.hashicorp.com/packer/getting-started/install#installing-packer

# 1. Building box images with Packer

Access the folder with the following command:

~~~bash
cd packer/
~~~

For each box run the proper command and wait, a virtual box window will pop up but ignore it.

~~~bash
packer build -parallel-builds=1 k8s-docker.json
packer build -parallel-builds=1 k8s-containerd.json
packer build -parallel-builds=1 k8s-crio.json
~~~

# 2. Add the new boxes to Vagrant

Basta rodar os respectivos comandos de acordo com o nome.
We just need to run the following commands acording with the container runtime name

~~~bash
vagrant box add output/k8s-docker-virtualbox.box --name wsilva/k8s-docker-virtualbox --provider virtualbox --force

vagrant box add output/k8s-containerd-virtualbox.box --name wsilva/k8s-containerd-virtualbox --provider virtualbox --force

vagrant box add output/k8s-crio-virtualbox.box --name wsilva/k8s-crio-virtualbox --provider virtualbox --force
~~~

>Pay attention to the box name: `wsilva/k8s-...`, if you want to you can switch it to a desired name but you must also change it on `Vagrantfile`.
