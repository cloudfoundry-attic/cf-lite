
Vagrant.configure('2') do |config|
  config.vm.network :private_network, ip: '192.168.54.4', id: :local
end
