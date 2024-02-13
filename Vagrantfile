# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV['VAGRANT_NO_PARALLEL'] = 'yes'

# NUM_NODES=1
NUM_NODES = ENV['NUM_NODES'] || 2
RUNTIME = ENV['RUNTIME'] || "containerd"
K8S_VERSION = ENV['K8S_VERSION'] || "1.29"

Vagrant.configure(2) do |config|

    config.vm.box = "generic/ubuntu2204"
    config.vm.box_check_update  = false
    config.trigger.after :up do |trigger|
        trigger.warn = "Running swap off"
        trigger.run_remote = {inline: "sudo swapoff -a"}
    end
  
    # setting up master host
    config.vm.define "k8smaster", primary: true do |master|
        master.vm.hostname = "k8smaster"
        master.vm.network "private_network", ip: "192.168.7.10"
        config.vm.synced_folder ".", "/vagrant"
        config.vm.provider :virtualbox do |vb|
            vb.customize ["modifyvm", :id, "--memory", "2048"]
            vb.customize ["modifyvm", :id, "--cpus", "2"]
        end
        master.vm.provision "shell" do |s|
            s.path = "setup-prerequisites.sh"
        end
        master.vm.provision "shell" do |s|
            s.path = "setup-k8s.sh"
            s.args = K8S_VERSION
        end
        master.vm.provision "shell" do |s|
            s.path = "setup-with-" + RUNTIME + ".sh"
            s.args = K8S_VERSION
        end
        master.vm.provision "shell" do |s|
            s.path = "setup-hostnames.sh"
        end
        master.trigger.after :up do |trigger|
            trigger.warn = "Teste de run no k8smaster"
            trigger.run_remote = {inline: "echo 'End of setting up k8smaster!!!'"}
        end

    end

    # setting up the nodes hosts
    (1..NUM_NODES.to_i).each do |node_number|
        
        node_name = "k8snode#{node_number}"

        config.vm.define node_name do |node|
            node.vm.hostname = node_name
            counter = 10 + node_number 
            node_ip = "192.168.7.#{counter}"
            node.vm.network "private_network", ip: node_ip
            config.vm.provider :virtualbox do |vb|
               vb.customize ["modifyvm", :id, "--memory", "2048"]
               vb.customize ["modifyvm", :id, "--cpus", "2"]
            end
            node.vm.provision "shell" do |s|
                s.path = "setup-prerequisites.sh"
            end
            node.vm.provision "shell" do |s|
                s.path = "setup-k8s.sh"
                s.args = K8S_VERSION
            end
            node.vm.provision "shell" do |s|
                s.path = "setup-with-" + RUNTIME + ".sh"
                s.args = K8S_VERSION
            end
            node.vm.provision "shell" do |s|
                s.path = "setup-hostnames.sh"
            end
            node.trigger.after :up do |trigger|
                trigger.warn = "Teste de run no " + node_name + ""
                trigger.run_remote = {inline: "echo 'yabadabadoooooo from " + node_name + "!!!!'"}
            end

        end
    end
end
