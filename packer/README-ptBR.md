# 0. Instalar (ou atualizar) dependências

## Mac OS com homebrew (https://brew.sh/)

```bash
brew upgrade --cask virtualbox vagrant  jq
```

ou

```bash
brew install --cask virtualbox vagrant packer jq
```

## Windows com chocolatey

```bash
choco upgrade virtualbox vagrant packer
```

ou

```bash
choco install virtualbox vagrant packer
```

## Linux, FreeBSD, OpenBSD, outros

Você deve saber o que está fazendo. Mas aqui seguem alguns links para ajudar:

- https://www.virtualbox.org/wiki/Downloads
- https://www.vagrantup.com/downloads.html
- https://learn.hashicorp.com/packer/getting-started/install#installing-packer

# 1. Construindo as imagens com Packer

Acessar a pasta packer:

```bash
cd packer/
```

Para cada box rodar o respectivo comando e aguardar. Uma janela do virtualbox vai abrir mas ignore ela.

```bash
packer build -parallel-builds=1 k8s-docker-virtualbox.json
packer build -parallel-builds=1 k8s-containerd-virtualbox.json
packer build -parallel-builds=1 k8s-crio-virtualbox.json
```

Para Windows:

```bash
packer build -parallel-builds=1 k8s-docker-hyperv.json
packer build -parallel-builds=1 k8s-containerd-hyperv.json
packer build -parallel-builds=1 k8s-crio-hyperv.json
```

# 2. Adicionar as box criadas ao Vagrant

Basta rodar os respectivos comandos de acordo com o nome do tipo de contêiner.

```bash
vagrant box add output/k8s-docker-virtualbox-metadata.json --name wsilva/k8s-docker --provider virtualbox --force

vagrant box add output/k8s-containerd-virtualbox-metadata.json --name wsilva/k8s-containerd --provider virtualbox --force

vagrant box add output/k8s-crio-virtualbox-metadata.json --name wsilva/k8s-crio --provider virtualbox --force
```

>Atenção ao nome da Box `wsilva/k8s-...`, se quiser alterar para seu nome então também deve ser alterado no `Vagrantfile`.

>Atenção também ao url para o `arquivo.box` dentro dos arquivos `k8s-...-virtualbox-metadata.json`, como tem que ser o caminho absoluto é provavel que seu código esteja em outra pasta.

Para windows

```bash

vagrant box add packer/output/k8s-docker-hyperv-metadata.json --name wsilva/k8s-docker --provider hyperv --force

vagrant box add packer/output/k8s-containerd-hyperv-metadata.json --name wsilva/k8s-containerd --provider hyperv --force

vagrant box add packer/output/k8s-crio-hyperv-metadata.json --name wsilva/k8s-crio --provider hyperv --force
```
