# -*- mode: ruby -*-
# vi: set ft=ruby :

# NUM_NODES=1
NUM_NODES = ENV['NUM_NODES'] || 2
RUNTIME = ENV['RUNTIME'] || "docker"

Vagrant.configure(2) do |config|

    # config.vm.box = "generic/ubuntu1804"
    # config.vm.box_version = "3.0.10"
    config.vm.box = "wsilva/k8s-" + RUNTIME

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
    config.vm.define "k8smaster", primary: true do |master|
        master.vm.hostname = "k8smaster"
        master.vm.network "private_network", ip: "192.168.7.10"
        config.vm.synced_folder ".", "/vagrant"
        config.vm.provider :virtualbox do |vb|
            vb.customize ["modifyvm", :id, "--memory", "2048"]
            vb.customize ["modifyvm", :id, "--cpus", "2"]
        end
        
        # config.vm.provider :hyperv do |hv| # windows
        #     hv.memory = 2048
        #     hv.cpus = 2
        # end

        master.vm.provision "shell" do |s|
            s.path = "setup-with-" + RUNTIME + ".sh"
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
            
            # config.vm.provider :hyperv do |hv| # windows
            #     hv.memory = 1024
            #     hv.cpus = 2
            # end

            node.vm.provision "shell" do |s|
                s.path = "setup-with-" + RUNTIME + ".sh"
            end
        end
    end
end
