
# Kubernetes Vagrant

Projeto para levantar 3 VMs rodando Ubuntu 16.04 puras, instalar Kubernetes e suas dependencias e levantar um cluster entre as 3 máquinas com 1 master e 2 nodes.

## Clone do projeto

Se tiver a imagem baixada previamente de https://vagrantcloud.com/bento/boxes/ubuntu-16.04/versions/201808.24.0/providers/virtualbox.box:

~~~bash
vagrant box add "bento/ubuntu-16.04" ./virtualbox.box
~~~

## Iniciando

Subindo o cluster de 3 nodes kubernetes (1 master + 2 nodes):

~~~bash
./setup-cluster.sh
~~~

## Configurando o client

Basta exportar essa env var

~~~bash
export KUBECONFIG=kubernetes-vagrant-config:$HOME/.kube/config
~~~

Em caso de conflito de nomes podemos tentar inverter:

~~~bash
export KUBECONFIG=$HOME/.kube/config:kubernetes-vagrant-config
~~~