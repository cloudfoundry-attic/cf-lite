
# The contents below were provided by the Packer Vagrant post-processor

Vagrant.configure("2") do |config|
  config.vm.base_mac = "0800272CFE63"
end


# The contents below (if any) are custom contents provided by the
# Packer template during image build.

Vagrant.configure('2') do |config|
  config.vm.box = 'cf-lite'
  #config.vm.box_version = '92'
  config.vm.network :private_network, ip: '192.168.54.4', id: :local
  config.vm.provision "shell", inline: "sudo apt-get install -y expect"

  config.vm.provider :aws do |v, override|
    #override.vm.synced_folder "scripts/", "/scripts"
    #override.vm.provision "shell", inline: "sudo chmod 777 /scripts/bosh-cck.sh"
    #override.vm.provision "shell", inline: "sudo /scripts/bosh-cck.sh"
    override.vm.provision "file", source: "scripts/bosh-cck-aws.sh", destination: "bosh-cck.sh"
    override.vm.provision "shell", inline: "sudo chmod 777 /home/ubuntu/bosh-cck.sh"
    override.vm.provision "shell", inline: "sudo /home/ubuntu/bosh-cck.sh"
  end

  config.vm.provider :virtualbox do |v, override|
    v.memory = 12000
    override.vm.provision "shell", inline: " sudo chmod 777 /vagrant/scripts/bosh-cck.sh && su -- vagrant -c /vagrant/scripts/bosh-cck.sh"
    override.vm.provision "shell", inline: " sudo chmod 777 /vagrant/scripts/start-sample-app.sh && su -- vagrant -c /vagrant/scripts/start-sample-app.sh"
  end
end

