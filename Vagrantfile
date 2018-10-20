# -*- mode: ruby -*-
# vi: set ft=ruby :

$common_script = <<-SCRIPT
# Install kubernetes
apt-get update && apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y htop kubelet kubeadm kubectl

# kubelet requires swap off
swapoff -a
# keep swap off after reboot
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
# set up cgroup driver
sed -i '/Service=/a Environment="KUBELET_EXTRA_ARGS=--cgroup-driver=cgroupfs"\n' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# reset if something is already defined
echo "Reset kubeadm"
kubeadm reset --force
SCRIPT

$master_script = <<-SCRIPT
# set up k8s
echo "Initialising kubeadm"
kubeadm init --apiserver-advertise-address 192.168.7.11

# Set up admin creds for the vagrant user
echo "Copying credentials to /home/vagrant..."
sudo --user=vagrant mkdir -p /home/vagrant/.kube
cp -rf /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown $(id -u vagrant):$(id -g vagrant) /home/vagrant/.kube/config

# Checking if api is up
sudo --user=vagrant kubectl --kubeconfig=/home/vagrant/.kube/config get node
SUCCESS=$?
while [ $SUCCESS -ne 0 ]
do
  echo "No API available yet, trying in 10 seconds"
  sleep 10
  sudo --user=vagrant kubectl --kubeconfig=/home/vagrant/.kube/config get node
  SUCCESS=$?
done

echo "K8s api is live"
echo "Installing calico network"

# install network
sudo --user=vagrant kubectl --kubeconfig=/home/vagrant/.kube/config apply -f https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/kubeadm/1.7/calico.yaml

# freeing master to also schedule pods on it
sleep 60
# sudo --user=vagrant kubectl --kubeconfig=/home/vagrant/.kube/config taint nodes --all node-role.kubernetes.io/master- 
SCRIPT

$node_script = <<-SCRIPT
echo "I am a node, waiting"
sleep 6
echo "I think I am ready"
SCRIPT

# 1 master + 2 nodes
NUM_NODES=3

Vagrant.configure('2') do |config|
    
    
    (1..NUM_NODES).each do |node_number|

        if node_number == 1
            node_name = "k8smaster"
        else
            node_name = "k8snode#{node_number}"
        end

        config.vm.define node_name do |node|

            node.vm.box = "bento/ubuntu-16.04"
            node.vm.hostname = "#{node_name}"
            node.vm.provision "docker"
            node.vm.provision "shell", inline: $common_script

            node_address = 10 + node_number 
            node_ip = "192.168.7.#{node_address}"
            node.vm.network 'private_network', ip: "#{node_ip}"

            if node_name == "k8smaster"
                node.vm.provision "shell", inline: $master_script
                NODE_MEM = '2048'
            else
                node.vm.provision "shell", inline: $node_script
                NODE_MEM = '1024'
            end

            node.vm.provider 'virtualbox' do |vb|
                vb.memory = NODE_MEM
            end

        end
    end
end
