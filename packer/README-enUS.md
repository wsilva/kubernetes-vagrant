# 0. Install (or upgrade) dependencies

## Mac OS with homebrew (https://brew.sh/)

```bash
brew upgrade --cask virtualbox vagrant packer jq
```

or

```bash
brew install --cask virtualbox vagrant packer jq
```

## Windows with chocolatey

```bash
choco upgrade virtualbox vagrant packer
```

or

```bash
choco install virtualbox vagrant packer
```

## Linux, FreeBSD, OpenBSD, and others

You may know what to do. Here follow some links to help:

- https://www.virtualbox.org/wiki/Downloads
- https://www.vagrantup.com/downloads.html
- https://learn.hashicorp.com/packer/getting-started/install#installing-packer

# 1. Building box images with Packer

Access the folder with the following command:

```bash
cd packer/
```

For each box run the proper command and wait, a virtual box window will pop up but ignore it.

```bash
packer build -parallel-builds=1 k8s-docker-virtualbox.json
packer build -parallel-builds=1 k8s-containerd-virtualbox.json
packer build -parallel-builds=1 k8s-crio-virtualbox.json
```

For Windows:

```bash
packer build -parallel-builds=1 k8s-docker-hyperv.json
packer build -parallel-builds=1 k8s-containerd-hyperv.json
packer build -parallel-builds=1 k8s-crio-hyperv.json
```

# 2. Add the new boxes to Vagrant

Basta rodar os respectivos comandos de acordo com o nome.
We just need to run the following commands acording with the container runtime name

```bash
vagrant box add packer/output/k8s-docker-virtualbox-metadata.json --name wsilva/k8s-docker --provider virtualbox --force

vagrant box add packer/output/k8s-containerd-virtualbox-metadata.json --name wsilva/k8s-containerd --provider virtualbox --force

vagrant box add packer/output/k8s-crio-virtualbox-metadata.json --name wsilva/k8s-crio --provider virtualbox --force
```

>Pay attention to the box name: `wsilva/k8s-...`, if you want to you can switch it to a desired name but you must also change it on `Vagrantfile`.

>Atention also to the url to `file.box` inside the files `k8s-...-virtualbox-metadata.json`, as the full path is needed instead of the relative path probably your code is placed in a different folder.

For Windows

```bash

vagrant box add packer/output/k8s-docker-hyperv-metadata.json --name wsilva/k8s-docker --provider hyperv --

vagrant box add packer/output/k8s-containerd-hyperv-metadata.json --name wsilva/k8s-containerd --provider hyperv --force

vagrant box add packer/output/k8s-crio-hyperv-metadata.json --name wsilva/k8s-crio --provider hyperv --force

```
