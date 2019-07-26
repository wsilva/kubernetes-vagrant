# -*- mode: ruby -*-
# vi: set ft=ruby :

NUM_NODES=2

Vagrant.configure(2) do |config|

    config.vm.box = "ubuntu/bionic64"

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
        master.vm.provision "shell" do |s|
            s.inline = $script

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
               vb.customize ["modifyvm", :id, "--cpus", "2"]
            end
            node.vm.provision "shell" do |s|
                s.inline = $script
            end
        end
    end
end

# provision script
$script = <<-SCRIPT

# apt stuff
echo "-------------------------------"
echo "Updating stuff APT"
echo "-------------------------------"
apt-get update
apt-get upgrade -y


# Allow for network forwarding in IP Tables
echo "-------------------------------"
echo "Allow for network forwarding in IP Tables"
echo "-------------------------------"
sysctl net.bridge.bridge-nf-call-iptables=1

# kubernetes requires swap off
echo "-------------------------------"
echo "Turning the swap off"
echo "-------------------------------"
swapoff -a
# keep swap off after reboot
cat /etc/fstab | grep '^[#]' | grep swap
if [ "$?" -ne 0 ]
then
    sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
fi

# Install last stable Docker
echo "-------------------------------"
echo "Installing Docker"
echo "-------------------------------"
docker version
if [ "$?" -ne 0 ]
then
    curl -fsSL https://get.docker.com | bash
fi
usermod -aG docker vagrant

# Change Docker cgroups driver from standard cgroupsfs to systemd - the check command: docker info | grep 'Cgroup Driver'
# link to the issue: https://github.com/kubernetes/kubeadm/issues/1218
echo "-------------------------------"
echo "Change Docker cgroups driver from standard cgroupsfs to systemd"
echo "-------------------------------"
cat <<EOF >/etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
mkdir -p /etc/systemd/system/docker.service.d
systemctl daemon-reload
systemctl restart docker

# Install kubernetes
echo "-------------------------------"
echo "Installing kubelet, kubeadm, kubeclt, etc"
echo "-------------------------------"
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
kubeadm version
if [ "$?" -ne 0 ]
then
    apt-get update && apt-get install -y apt-transport-https bash-completion htop kubelet kubeadm kubectl
fi

# reset if something is already defined
echo "-------------------------------"
echo "Reset Kubeadm if it is already set"
echo "-------------------------------"
echo "Reset kubeadm"
kubeadm reset --force

# set up completion
echo "-------------------------------"
echo "Set up bash completion"
echo "-------------------------------"
kubeadm completion bash > /etc/bash_completion.d/kubeadm
kubectl completion bash > /etc/bash_completion.d/kubectl

# Download latest container images
echo "-------------------------------"
echo "Downloading k8s container images"
echo "-------------------------------"
kubeadm config images pull 

# Fix Kubelet config for Debian like machines to avoid issues while port forwarding or exec -it
echo "-------------------------------"
echo "Create custom kubelet config file"
echo "-------------------------------"
echo "KUBELET_EXTRA_ARGS=\"--node-ip=$(ifconfig | grep 192.168.7 | awk '{print $2}')\"" | tee /etc/default/kubelet

SCRIPT