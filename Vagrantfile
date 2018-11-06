# -*- mode: ruby -*-
# vi: set ft=ruby :

NUM_NODES=2
$k8sversion = "1.11.3-00"

Vagrant.configure(2) do |config|

    config.vm.box = "bento/ubuntu-16.04"

    # using cache for apt
    if Vagrant.has_plugin?("vagrant-cachier")
        config.cache.synced_folder_opts = {
            owner: "_apt",
            group: "_apt",
            mount_options: ["dmode=777", "fmode=666"]
        }
        config.cache.scope = :box
    end
  
    # setting up master host
    config.vm.define "k8smaster" do |master|
      master.vm.hostname = "k8smaster"
      master.vm.network "private_network", ip: "192.168.7.10"
      config.vm.provider :virtualbox do |vb|
         vb.customize ["modifyvm", :id, "--memory", "2048"]
         vb.customize ["modifyvm", :id, "--cpus", "2"]
      end
      master.vm.provision "docker"
        master.vm.provision "shell" do |s|
            s.inline = $script
            s.args   = $k8sversion
        end
    end

    # setting up the nodes hosts
    (1..NUM_NODES).each do |node_number|
        
        node_name = "k8snode#{node_number}"

        config.vm.define node_name do |node|
            node.vm.hostname = node_name
            counter = 10 + node_number 
            node_ip = "192.168.7.#{counter}"
            node.vm.network "private_network", ip: node_ip
            config.vm.provider :virtualbox do |vb|
               vb.customize ["modifyvm", :id, "--memory", "1024"]
               vb.customize ["modifyvm", :id, "--cpus", "1"]
            end
            node.vm.provision "docker"
            node.vm.provision "shell" do |s|
                s.inline = $script
                s.args   = $k8sversion
            end
        end
    end
end

# provision script
$script = <<-SCRIPT
# Install kubernetes
echo "-------------------------------"
echo "Installing kubelet, kubeadm, kubeclt, etc"
echo "-------------------------------"
apt-get update && apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y htop kubelet=$1 kubeadm=$1 kubectl=$1

# kubelet requires swap off
echo "-------------------------------"
echo "Turning the swap off"
echo "-------------------------------"
swapoff -a
# keep swap off after reboot
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
# set up cgroup driver
sed -i '/Service=/a Environment="KUBELET_EXTRA_ARGS=--cgroup-driver=cgroupfs"\n' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# reset if something is already defined
echo "-------------------------------"
echo "Reset Kubeadm if it is already set"
echo "-------------------------------"
echo "Reset kubeadm"
kubeadm reset --force
SCRIPT