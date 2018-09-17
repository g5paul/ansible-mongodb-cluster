# Defines our Vagrant environment
#
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  N = 3
  (1..N).each do |i|
    config.vm.define "mongo#{i}" do |node|
        # Centos 7
        node.vm.box = "centos/7"
        # Ubuntu 16.04/xenial
        #node.vm.box = "ubuntu/xenial64"
        # Debian 9/stretch
        #node.vm.box = "debian/stretch64"
        node.vm.hostname = "mongo#{i}"
        node.vm.network :private_network, ip: "11.0.0.1#{i}"
        node.vm.provider "virtualbox" do |vb|
          vb.memory = "256" # Centos 
          #vb.memory = "512" # Ubuntu / Debian
        end
        node.vm.provision :shell, path: "bootstrap.sh", run: "once"

        if i == N
          node.vm.provision :ansible do |ansible|
            ansible.playbook          = "mongodb/site.yml"
            ansible.limit             = "all"
            ansible.sudo              = true # Vagrant 1.9.x
#            ansible.become              = true # Vagrant 2.x
#            ansible.verbose         = '-vvvv'
            ansible.host_vars = {
              "mongo1" => {"mongod_port" => 2700},
              "mongo2" => {"mongod_port" => 2701},
              "mongo3" => {"mongod_port" => 2702}
            }
            ansible.groups = {
              "mongo_servers" => ["mongo1", "mongo2", "mongo3"],
              "replication_servers" => ["mongo1", "mongo2", "mongo3"],
              "mongoc_servers" => ["mongo1", "mongo2", "mongo3"],
              "mongos_servers" => ["mongo1", "mongo2"]
            }
            ansible.extra_vars = {
              mongo_adduser: "true",
            }
          end
        end
    end
  end

end
