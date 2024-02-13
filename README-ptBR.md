# Kubernetes Vagrant

Esse projeto entrega 3 máquinas virtuais Virtualbox rodando Ubuntu 22.04 com `kubeadm` e dependências instaladas mais as instruções para montar seu cluster `Kubernetes` multinode (1 master + 2 workers).

Foi atualizado e testado com *Kubernetes 1.29*, *Calico 3.26*, *Docker 25.0.3*, *Containerd 1.6.28 e *Cri-o 1.29*.

- [Kubernetes Vagrant](#kubernetes-vagrant)
  - [0. Instalar (ou atualizar) dependencias](#0-instalar-ou-atualizar-dependencias)
    - [Mac OS com homebrew (https://brew.sh/)](#mac-os-com-homebrew-httpsbrewsh)
    - [Windows com chocolatey](#windows-com-chocolatey)
    - [Linux, FreeBSD, OpenBSD, outros](#linux-freebsd-openbsd-outros)
  - [1. Baixar esse repositório se ainda não o fez](#1-baixar-esse-repositório-se-ainda-não-o-fez)
  - [2. Montando o cluster](#2-montando-o-cluster)
    - [Remover arquivo antigo de configuração](#remover-arquivo-antigo-de-configuração)
    - [Levantando as máquinas](#levantando-as-máquinas)
    - [Fazer reset se tiver sido criado anteriormente](#fazer-reset-se-tiver-sido-criado-anteriormente)
    - [Inicializar o nó master](#inicializar-o-nó-master)
    - [Arquivo de configuração](#arquivo-de-configuração)
    - [Configurar rede](#configurar-rede)
    - [Adicionar nós worker](#adicionar-nós-worker)
  - [3. Usando o cluster](#3-usando-o-cluster)
    - [Apontar o `kubectl` para usá-lo](#apontar-o-kubectl-para-usá-lo)
  - [4. Desligando ou reiniciando](#4-desligando-ou-reiniciando)
  - [5. Dicas Bônus (Opcional)](#5-dicas-bônus-opcional)
    - [Tudo de uma vez](#tudo-de-uma-vez)
    - [Definindo os hosts localmente](#definindo-os-hosts-localmente)
    - [Misturando os runtimes](#misturando-os-runtimes)
    - [Removendo tudo](#removendo-tudo)

## 0. Instalar (ou atualizar) dependencias

Instalar Virtualbox, Vagrant, e a kubernetes cli.

### Mac OS com homebrew (https://brew.sh/)

```bash
brew upgrade --cask virtualbox vagrant
brew upgrade kubernetes-cli
```

ou

```bash
brew install --cask virtualbox vagrant
brew install kubernetes-cli
```

### Windows com chocolatey

```bash
choco upgrade virtualbox vagrant kubernetes-cli
```

ou

```bash
choco install virtualbox vagrant kubernetes-cli
```

### Linux, FreeBSD, OpenBSD, outros

Você deve saber o que está fazendo. Mas aqui seguem alguns links para ajudar:

- https://www.virtualbox.org/wiki/Downloads
- https://www.vagrantup.com/downloads.html
- https://kubernetes.io/docs/tasks/tools/install-kubectl/

## 1. Baixar esse repositório se ainda não o fez

Primeiro clonamos o projeto:

```bash
git clone https://github.com/wsilva/kubernetes-vagrant
cd kubernetes-vagrant
```

## 2. Montando o cluster

### Remover arquivo antigo de configuração

Remover arquivo de configuração antigo criado previamente se existir

```bash
rm -f ./kubernetes-vagrant-config
```

### Levantando as máquinas

Inicie as máquinas ou reprovisione, leva pouco menos de 10 minutos a primeira vez.

Para runtime Docker:

```bash
export RUNTIME=docker
$Env:RUNTIME = "docker"
vagrant up --provision
```

Para runtime Containerd:

```bash
export RUNTIME=containerd
$Env:RUNTIME = "containerd"
vagrant up --provision
```

Para runtime Cri-o:

```bash
export RUNTIME=crio
$Env:RUNTIME = "crio"
vagrant up --provision
```

> Nota: 
> Se não informado o runtime usado será `containerd`.

### Fazer reset se tiver sido criado anteriormente

```bash
vagrant ssh k8smaster -c "sudo kubeadm reset --force" && \
vagrant ssh k8snode1 -c "sudo kubeadm reset --force" && \
vagrant ssh k8snode2 -c "sudo kubeadm reset --force"
```

### Inicializar o nó master

Para runtime Docker:

```bash
vagrant ssh k8smaster -c "sudo kubeadm init --apiserver-advertise-address 192.168.7.10 --pod-network-cidr=172.16.0.0/16 --cri-socket unix:///var/run/cri-dockerd.sock"
```

Para runtime Containerd:

```bash
vagrant ssh k8smaster -c "sudo kubeadm init --apiserver-advertise-address 192.168.7.10 --pod-network-cidr=172.16.0.0/16 --cri-socket unix:///run/containerd/containerd.sock"
```

Para runtime Cri-o:

```bash
vagrant ssh k8smaster -c "sudo kubeadm init --apiserver-advertise-address 192.168.7.10 --pod-network-cidr=172.16.0.0/16 --cri-socket unix:///var/run/crio/crio.sock"
```

### Arquivo de configuração

Criar a pasta e arquivo de configuração, definir permissões, renomeia recurso e manda para pasta compartilhada:

```bash
vagrant ssh k8smaster -c "mkdir -p /home/vagrant/.kube"

vagrant ssh k8smaster -c "sudo cp -rf /etc/kubernetes/admin.conf /home/vagrant/.kube/config"

vagrant ssh k8smaster -c "sudo chown vagrant:vagrant /home/vagrant/.kube/config"

vagrant ssh k8smaster -c "cp ~/.kube/config /vagrant/kubernetes-vagrant-config"

vagrant ssh k8smaster -c "sed -i 's/kubernetes-admin/k8s/g' /vagrant/kubernetes-vagrant-config"

vagrant ssh k8smaster -c "sed -i 's/kubernetes/vagrant/g' /vagrant/kubernetes-vagrant-config"
```

### Configurar rede

Instalando o calico como CNI para o kubernetes

```bash
vagrant ssh k8smaster -c \
"kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml"
```

### Adicionar nós worker

Pegar o token e a chave pública do master

```bash
export KUBEADMTOKEN=$(vagrant ssh k8smaster -- sudo kubeadm token list | grep init | awk '{print $1}')

export KUBEADMPUBKEY=$(vagrant ssh k8smaster -c "sudo openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'")
```

Adicionar os nós no cluster.

Para Docker:

```bash
vagrant ssh k8snode1 -c "sudo kubeadm join 192.168.7.10:6443 --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY} --cri-socket unix:///var/run/cri-dockerd.sock"

vagrant ssh k8snode2 -c "sudo kubeadm join 192.168.7.10:6443 --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY} --cri-socket unix:///var/run/cri-dockerd.sock"
```

Para Containerd

```bash
vagrant ssh k8snode1 -c "sudo kubeadm join 192.168.7.10:6443 --cri-socket unix:///run/containerd/containerd.sock --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY} --cri-socket unix:///run/containerd/containerd.sock"

vagrant ssh k8snode2 -c "sudo kubeadm join 192.168.7.10:6443 --cri-socket unix:///run/containerd/containerd.sock --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY} --cri-socket unix:///run/containerd/containerd.sock"
```

Para Cri-o

```bash
vagrant ssh k8snode1 -c "sudo kubeadm join 192.168.7.10:6443 --cri-socket unix:///var/run/crio/crio.sock --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY} --cri-socket unix:///var/run/crio/crio.sock" 

vagrant ssh k8snode2 -c "sudo kubeadm join 192.168.7.10:6443 --cri-socket unix:///var/run/crio/crio.sock --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY} --cri-socket unix:///var/run/crio/crio.sock"
```

## 3. Usando o cluster

### Apontar o `kubectl` para usá-lo

Podemos fazer um merge do arquivo gerado `kubernetes-vagrant-config` com o nosso `$HOME/.kube/config` e refazer a cada vez que subirmos esse cluster.

Ou podemos exportar como variável de ambiente e apontar para usar ambos arquivos:

```bash
export KUBECONFIG=$HOME/.kube/config:$PWD/kubernetes-vagrant-config
```

Selecione o cluster vagrant kubernetes recem criado:

```bash
kubectl config use-context k8s@vagrant
```

## 4. Desligando ou reiniciando

Para desligar rodamos `vagrant halt`.

Quando precisar do cluster novamente rode `vagrant up` novamente e aguarde.

Se hover algum problema podemos reprovisinar rodando o [passo 2](#2-montando-o-cluster) e o [passo 3](#3-usando-o-cluster) de novo, vai rolar o reprovisionamento mas muito mais rápido que da primeira vez.


## 5. Dicas Bônus (Opcional)

### Tudo de uma vez

Se você é preguiçoso como eu pode rodar de uma vez o seguinte comando depois de um `vagrant up` comum.

Com Docker:

```bash
export RUNTIME=docker \
&& vagrant up --provision \
&& vagrant ssh k8smaster -c "sudo kubeadm reset --force || echo 'Kubeadm already reset'" \
&& vagrant ssh k8snode1 -c "sudo kubeadm reset --force || echo 'Kubeadm already reset'" \
&& vagrant ssh k8snode2 -c "sudo kubeadm reset --force || echo 'Kubeadm already reset'" \
&& vagrant ssh k8smaster -c "sudo kubeadm init --apiserver-advertise-address 192.168.7.10 --pod-network-cidr=172.16.0.0/16 --cri-socket unix:///var/run/cri-dockerd.sock" \
&& vagrant ssh k8smaster -c "mkdir -p /home/vagrant/.kube" \
&& vagrant ssh k8smaster -c "sudo cp -rf /etc/kubernetes/admin.conf /home/vagrant/.kube/config" \
&& vagrant ssh k8smaster -c "sudo chown vagrant:vagrant /home/vagrant/.kube/config" \
&& vagrant ssh k8smaster -c "kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml" \
&& export KUBEADMTOKEN=$(vagrant ssh k8smaster -- sudo kubeadm token list | grep init | awk '{print $1}') \
&& export KUBEADMPUBKEY=$(vagrant ssh k8smaster -c "sudo openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'") \
&& vagrant ssh k8snode1 -c "sudo kubeadm join 192.168.7.10:6443 --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY} --cri-socket unix:///var/run/cri-dockerd.sock" \
&& vagrant ssh k8snode2 -c "sudo kubeadm join 192.168.7.10:6443 --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY} --cri-socket unix:///var/run/cri-dockerd.sock" \
&& vagrant ssh k8smaster -c "cp ~/.kube/config /vagrant/kubernetes-vagrant-config" \
&& vagrant ssh k8smaster -c "sed -i 's/kubernetes-admin/k8s/g' /vagrant/kubernetes-vagrant-config" \
&& vagrant ssh k8smaster -c "sed -i 's/kubernetes/vagrant/g' /vagrant/kubernetes-vagrant-config" \
&& export KUBECONFIG=$HOME/.kube/config:$PWD/kubernetes-vagrant-config \
&& kubectl config use-context k8s@vagrant
```

Com Containerd:

```bash
export RUNTIME=containerd \
&& vagrant up --provision \
&& vagrant ssh k8smaster -c "sudo kubeadm reset --force || echo 'Kubeadm already reset'" \
&& vagrant ssh k8snode1 -c "sudo kubeadm reset --force || echo 'Kubeadm already reset'" \
&& vagrant ssh k8snode2 -c "sudo kubeadm reset --force || echo 'Kubeadm already reset'" \
&& vagrant ssh k8smaster -c "sudo kubeadm init --cri-socket unix:///run/containerd/containerd.sock --apiserver-advertise-address 192.168.7.10 --pod-network-cidr=172.16.0.0/16 --cri-socket unix:///run/containerd/containerd.sock" \
&& vagrant ssh k8smaster -c "mkdir -p /home/vagrant/.kube" \
&& vagrant ssh k8smaster -c "sudo cp -rf /etc/kubernetes/admin.conf /home/vagrant/.kube/config" \
&& vagrant ssh k8smaster -c "sudo chown vagrant:vagrant /home/vagrant/.kube/config" \
&& vagrant ssh k8smaster -c "kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml" \
&& export KUBEADMTOKEN=$(vagrant ssh k8smaster -- sudo kubeadm token list | grep init | awk '{print $1}') \
&& export KUBEADMPUBKEY=$(vagrant ssh k8smaster -c "sudo openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'") \
&& vagrant ssh k8snode1 -c "sudo kubeadm join 192.168.7.10:6443 --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY} --cri-socket unix:///run/containerd/containerd.sock" \
&& vagrant ssh k8snode2 -c "sudo kubeadm join 192.168.7.10:6443 --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY} --cri-socket unix:///run/containerd/containerd.sock" \
&& vagrant ssh k8smaster -c "cp ~/.kube/config /vagrant/kubernetes-vagrant-config" \
&& vagrant ssh k8smaster -c "sed -i 's/kubernetes-admin/k8s/g' /vagrant/kubernetes-vagrant-config" \
&& vagrant ssh k8smaster -c "sed -i 's/kubernetes/vagrant/g' /vagrant/kubernetes-vagrant-config" \
&& export KUBECONFIG=$HOME/.kube/config:$PWD/kubernetes-vagrant-config \
&& kubectl config use-context k8s@vagrant
```

Com Cri-o:

```bash
export RUNTIME=crio \
&& vagrant up --provision \
&& vagrant ssh k8smaster -c "sudo kubeadm reset --force || echo 'Kubeadm already reset'" \
&& vagrant ssh k8snode1 -c "sudo kubeadm reset --force || echo 'Kubeadm already reset'" \
&& vagrant ssh k8snode2 -c "sudo kubeadm reset --force || echo 'Kubeadm already reset'" \
&& vagrant ssh k8smaster -c "sudo kubeadm init --apiserver-advertise-address 192.168.7.10 --pod-network-cidr=172.16.0.0/16 --cri-socket unix:///var/run/crio/crio.sock" \
&& vagrant ssh k8smaster -c "mkdir -p /home/vagrant/.kube" \
&& vagrant ssh k8smaster -c "sudo cp -rf /etc/kubernetes/admin.conf /home/vagrant/.kube/config" \
&& vagrant ssh k8smaster -c "sudo chown vagrant:vagrant /home/vagrant/.kube/config" \
&& vagrant ssh k8smaster -c "kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml" \
&& export KUBEADMTOKEN=$(vagrant ssh k8smaster -- sudo kubeadm token list | grep init | awk '{print $1}') \
&& export KUBEADMPUBKEY=$(vagrant ssh k8smaster -c "sudo openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'") \
&& vagrant ssh k8snode1 -c "sudo kubeadm join 192.168.7.10:6443 --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY} --cri-socket unix:///var/run/crio/crio.sock" \
&& vagrant ssh k8snode2 -c "sudo kubeadm join 192.168.7.10:6443 --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY} --cri-socket unix:///var/run/crio/crio.sock" \
&& vagrant ssh k8smaster -c "cp ~/.kube/config /vagrant/kubernetes-vagrant-config" \
&& vagrant ssh k8smaster -c "sed -i 's/kubernetes-admin/k8s/g' /vagrant/kubernetes-vagrant-config" \
&& vagrant ssh k8smaster -c "sed -i 's/kubernetes/vagrant/g' /vagrant/kubernetes-vagrant-config" \
&& export KUBECONFIG=$HOME/.kube/config:$PWD/kubernetes-vagrant-config \
&& kubectl config use-context k8s@vagrant
```

### Definindo os hosts localmente

As máquinas virtuais tem o endereços ip fixos mas podemos etidar o arquivo de hosts no Mac OS e no Linux para acessar facilmente as máquinas virtuais pelos nomes.

```bash
echo "192.168.7.10 k8smaster.local k8smaster" | sudo tee -a /etc/hosts
echo "192.168.7.11 k8snode1.local k8snode1" | sudo tee -a /etc/hosts
echo "192.168.7.12 k8snode2.local k8snode2" | sudo tee -a /etc/hosts
```

No windows temos que editar o arquivo `C:\Windows\System32\drivers\etc\hosts` como Administrador.

### Misturando os runtimes

Para misturar os runtimes de containers podemos definir o runtime a cada máquina:

```bash
export RUNTIME=containerd \
&& vagrant up k8smaster --provision \
&& KUBEADMTOKEN=$(vagrant ssh k8smaster -- sudo kubeadm token generate) \
&& vagrant ssh k8smaster -c "sudo kubeadm reset --force || echo 'Kubeadm already reset'" \
&& vagrant ssh k8smaster -c "sudo kubeadm init  --token ${KUBEADMTOKEN} --apiserver-advertise-address 192.168.7.10 --pod-network-cidr=172.16.0.0/16 --cri-socket unix:///run/containerd/containerd.sock" \
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
&& vagrant up k8snode1 --provision \
&& export KUBEADMTOKEN=$(vagrant ssh k8smaster -- sudo kubeadm token list | grep init | awk '{print $1}') \
&& export KUBEADMPUBKEY=$(vagrant ssh k8smaster -c "sudo openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'") \
&& vagrant ssh k8snode1 -c "sudo kubeadm reset --force || echo 'Kubeadm already reset'" \
&& vagrant ssh k8snode1 -c "sudo kubeadm join 192.168.7.10:6443 --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY} --cri-socket unix:///var/run/crio/crio.sock" \
&& export RUNTIME=docker \
&& vagrant up k8snode2 \
&& export KUBEADMTOKEN=$(vagrant ssh k8smaster -- sudo kubeadm token list | grep init | awk '{print $1}') \
&& export KUBEADMPUBKEY=$(vagrant ssh k8smaster -c "sudo openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'") \
&& vagrant ssh k8snode2 -c "sudo kubeadm reset --force || echo 'Kubeadm already reset'" \
&& vagrant ssh k8snode2 -c "sudo kubeadm join 192.168.7.10:6443 --token ${KUBEADMTOKEN} --discovery-token-ca-cert-hash sha256:${KUBEADMPUBKEY} --cri-socket unix:///var/run/cri-dockerd.sock"
```

## Removendo tudo

Para apagar as máquinas se quiser subir do zero:

```
vagrant destroy -f
```