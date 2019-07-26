- [Kubernetes Vagrant](#kubernetes-vagrant)
- [0. Instalar (ou atualizar) dependencias](#0-instalar--ou-atualizar--dependencias)
  * [OSX com homebrew (https://brew.sh/)](#osx-com-homebrew--https---brewsh--)
  * [Windows com chocolatey](#windows-com-chocolatey)
  * [Linux, FreeBSD, OpenBSD, outros](#linux--freebsd--openbsd--outros)
  * [Vagrant plugins](#vagrant-plugins)
  * [A base box do vagrant](#a-base-box-do-vagrant)
- [1. Baixar esse repositório se ainda não o fez](#1-baixar-esse-reposit-rio-se-ainda-n-o-o-fez)
- [2. Montando o cluster](#2-montando-o-cluster)
  * [Remover arquivo antigo de configuração](#remover-arquivo-antigo-de-configura--o)
  * [Levantando as máquinas](#levantando-as-m-quinas)
  * [Fazer reset se tiver sido criado anteriormente](#fazer-reset-se-tiver-sido-criado-anteriormente)
  * [Inicializar o nó master](#inicializar-o-n--master)
  * [Configurar rede](#configurar-rede)
  * [Adicionar nós worker](#adicionar-n-s-worker)
- [3. Configurar o kubconfig](#3-configurar-o-kubconfig)
  * [Pegar o novo arquivo de configuração](#pegar-o-novo-arquivo-de-configura--o)
  * [Apontar o `kubectl` para usá-lo](#apontar-o--kubectl--para-us--lo)
- [4. Desligando ou reiniciando](#4-desligando-ou-reiniciando)

# Kubernetes Vagrant

Esse projeto entrega 3 máquinas virtuais Virtualbox rodando Ubuntu 18.04 com `kubeadm` e dependências instaladas mais as instruções para montar seu cluster `Kubernetes` multinode (1 master + 2 workers).

Foi atualizado e testado com Kubernetes 1.15, Calico 3.8 e Docker 19.03.


# 0. Instalar (ou atualizar) dependencias

Instalar Virtualbox, Vagrant, os plugins vagrant-cachier e vagrant-vbguests e a kubernetes cli.

## OSX com homebrew (https://brew.sh/)

~~~bash
brew cask upgrade virtualbox vagrant
brew upgrade kubernetes-cli
~~~

ou

~~~bash
brew cask install virtualbox vagrant
brew install kubernetes-cli
~~~

## Windows com chocolatey

~~~bash
choco upgrade virtualbox vagrant kubernetes-cli
~~~

~~~bash
choco install virtualbox vagrant kubernetes-cli
~~~

## Linux, FreeBSD, OpenBSD, outros

Você deve saber o que está fazendo. Mas aqui seguem alguns links para ajudar:
 - https://www.virtualbox.org/wiki/Downloads
 - https://www.vagrantup.com/downloads.html
 - https://kubernetes.io/docs/tasks/tools/install-kubectl/

## Vagrant plugins

Instale um por vez, instalar ao mesmo tempo causa conflito de dependencia de versão.

~~~bash
vagrant plugin install vagrant-cachier
vagrant plugin install vagrant-vbguest
~~~

## A base box do vagrant

Instalar ou atualizar a box do Ubuntu 18.04

```bash
vagrant box add ubuntu/bionic64
```

```bash
vagrant box update ubuntu/bionic64
```

Leva cerca de 16 minutos.

# 1. Baixar esse repositório se ainda não o fez

Primeiro clonamos o projeto:

~~~bash
git clone https://github.com/wsilva/kubernetes-vagrant
cd kubernetes-vagrant
~~~


# 2. Montando o cluster

## Remover arquivo antigo de configuração

Remover arquivo de configuração antigo criado previamente

```bash
rm -f ./kubernetes-vagrant-config
```

## Levantando as máquinas

Inicie as máquinas ou reprovisione, leva cerca de 19 minutos em uma conexão de internet comum.

```bash
vagrant up --provision
```

\* Se quiser levantar uma máquina de cada vez você pode rodar:

```bash
vagrant up k8smaster --provision; vagrant up k8snode1 --provision; vagrant up k8snode2 --provision
```

Mas não faça em paralelo isso pode causar problemas devido ao cache do apt não estar pronto ainda. Para provisionar as máquinas em paralelo você pode usar uma sessão shell para cada máquina e desligar o plugin `vagrant-cachier`. Apenas comente a linha ```if Vagrant.has_plugin?("vagrant-cachier")``` e a linha ```end```  correspondente no `Vagrantfile`

## Fazer reset se tiver sido criado anteriormente

```bash
vagrant ssh k8smaster -c "sudo kubeadm reset --force" && \
vagrant ssh k8snode1 -c "sudo kubeadm reset --force" && \
vagrant ssh k8snode2 -c "sudo kubeadm reset --force"
```

## Inicializar o nó master

```bash
vagrant ssh k8smaster -c "sudo kubeadm init --apiserver-advertise-address 192.168.7.10 --pod-network-cidr=192.168.0.0/16"
```

Criar a pasta e arquivo de configuração e definir permissões no master.

```bash
vagrant ssh k8smaster -c "mkdir -p /home/vagrant/.kube"
```

```bash
vagrant ssh k8smaster -c "sudo cp -rf /etc/kubernetes/admin.conf /home/vagrant/.kube/config"
```

```bash
vagrant ssh k8smaster -c "sudo chown vagrant:vagrant /home/vagrant/.kube/config"
```

## Configurar rede

Configurar o CNI com o calico que suporta versão 1.15 do kubernetes

```bash
vagrant ssh k8smaster -c "kubectl apply -f https://docs.projectcalico.org/v3.8/manifests/calico.yaml"
```

Se quiser rodar pods no nó master (não recomendado)

```bash
vagrant ssh k8smaster -c "kubectl taint nodes --all node-role.kubernetes.io/master- "
```

## Adicionar nós worker

Pegar o token e a chave pública do master

```bash
export KUBEADMTOKEN=$(vagrant ssh k8smaster -- sudo kubeadm token list | grep init | awk '{print $1}')
```

```bash
export KUBEADMPUBKEY=$(vagrant ssh k8smaster -c "sudo openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'")
```

Adicionar os nós no cluster

```bash
vagrant ssh k8snode1 -c "sudo kubeadm join 192.168.7.10:6443 --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY}"
```

```bash
vagrant ssh k8snode2 -c "sudo kubeadm join 192.168.7.10:6443 --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY}"
```

Colocar rótulo de worker (opcional)

```bash
vagrant ssh k8smaster -c "kubectl label node k8snode1 node-role.kubernetes.io/node="
```

```bash
vagrant ssh k8smaster -c "kubectl label node k8snode2 node-role.kubernetes.io/node="
```


# 3. Configurar o kubconfig

## Pegar o novo arquivo de configuração

Copiar arquivo de configuração do nó master para a pasta compartilhada

```bash
vagrant ssh k8smaster -c "cp ~/.kube/config /vagrant/kubernetes-vagrant-config"
```

```bash
vagrant ssh k8smaster -c "sed -i 's/kubernetes-admin/k8s/g' /vagrant/kubernetes-vagrant-config"
```

```bash
vagrant ssh k8smaster -c "sed -i 's/kubernetes/vagrant/g' /vagrant/kubernetes-vagrant-config"
```

## Apontar o `kubectl` para usá-lo

Podemos fazer um merge do arquivo gerado ```kubernetes-vagrant-config``` com o nosso `$HOME/.kube/` e refazer a cada vez que subirmos esse cluster.

Ou podemos exportar como variável de ambiente e apontar para usar ambos arquivos:

~~~bash
export KUBECONFIG=$HOME/.kube/config:kubernetes-vagrant-config
~~~

Selecione o cluster vagrant kubernetes recem criado:

~~~bash
kubectl config use-context k8s@vagrant
~~~

# 4. Desligando ou reiniciando

Para desligar rodamos ```vagrant halt```. 

Quando precisar do cluster novamente rode o [passo 2](#2-montando-o-cluster) e o [passo 3](#3-configurar-o-kubconfig) de novo, vai rolar o reprovisionamento mas muito mais rápido que da primeira vez.

Mas se você é preguiçoso como eu pode rodar o seguinte comando depois de um `vagrant up` comum:

```bash
vagrant ssh k8smaster -c "sudo kubeadm reset --force" \
  && vagrant ssh k8snode1 -c "sudo kubeadm reset --force" \
  && vagrant ssh k8snode2 -c "sudo kubeadm reset --force" \
  && vagrant ssh k8smaster -c "sudo kubeadm init --apiserver-advertise-address 192.168.7.10 --pod-network-cidr=192.168.0.0/16" \
  && vagrant ssh k8smaster -c "mkdir -p /home/vagrant/.kube" \
  && vagrant ssh k8smaster -c "sudo cp -rf /etc/kubernetes/admin.conf /home/vagrant/.kube/config" \
  && vagrant ssh k8smaster -c "sudo chown vagrant:vagrant /home/vagrant/.kube/config" \
  && vagrant ssh k8smaster -c "kubectl apply -f https://docs.projectcalico.org/v3.8/manifests/calico.yaml" \
  && export KUBEADMTOKEN=$(vagrant ssh k8smaster -- sudo kubeadm token list | grep init | awk '{print $1}') \
  && export KUBEADMPUBKEY=$(vagrant ssh k8smaster -c "sudo openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'") \
  && vagrant ssh k8snode1 -c "sudo kubeadm join 192.168.7.10:6443 --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY}" \
  && vagrant ssh k8snode2 -c "sudo kubeadm join 192.168.7.10:6443 --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY}" \
  && vagrant ssh k8smaster -c "kubectl label node k8snode1 node-role.kubernetes.io/node=" \
  && vagrant ssh k8smaster -c "kubectl label node k8snode2 node-role.kubernetes.io/node=" \
  && vagrant ssh k8smaster -c "cp ~/.kube/config /vagrant/kubernetes-vagrant-config" \
  && vagrant ssh k8smaster -c "sed -i 's/kubernetes-admin/k8s/g' /vagrant/kubernetes-vagrant-config" \
  && vagrant ssh k8smaster -c "sed -i 's/kubernetes/vagrant/g' /vagrant/kubernetes-vagrant-config" \
  && export KUBECONFIG=$HOME/.kube/config:kubernetes-vagrant-config \
  && kubectl config use-context k8s@vagrant
```