# better error messages from Hash.fetch
env = ENV.to_hash

unless env.include?('BOSH_AWS_ACCESS_KEY_ID') && env.include?('BOSH_AWS_SECRET_ACCESS_KEY')
  raise 'BOSH_AWS_ACCESS_KEY_ID and BOSH_AWS_SECRET_ACCESS_KEY must be provided in the environment'
end

def tags_from_environment(env)
  values = [env.fetch('BOX_NAME', 'CF-Lite')]
  values.concat env.fetch('BOSH_LITE_TAG_VALUES', '').chomp.split(', ')

  keys = ['Name']
  keys.concat env.fetch('BOSH_LITE_TAG_KEYS', '').chomp.split(', ')

  raise 'Please provide the same number of keys and values!' if keys.length != values.length

  Hash[keys.zip(values)]
end

Vagrant.configure('2') do |config|
  config.vm.hostname = 'bosh-lite'
  config.vm.synced_folder '.', '/vagrant', disabled: true

  config.ssh.username = 'ubuntu'
  config.ssh.private_key_path = env.fetch('BOSH_LITE_PRIVATE_KEY', '~/.ssh/id_rsa_bosh')

  config.vm.provider :aws do |v|
    v.access_key_id =       env.fetch('BOSH_AWS_ACCESS_KEY_ID')
    v.secret_access_key =   env.fetch('BOSH_AWS_SECRET_ACCESS_KEY')
    v.keypair_name =        env.fetch('BOSH_LITE_KEYPAIR', 'bosh')
    v.block_device_mapping = [{
      :DeviceName => '/dev/sda1',
      'Ebs.VolumeSize' => env.fetch('bosh_LITE_DISK_SIZE', '50').to_i
    }]
    v.instance_type =       env.fetch('BOSH_LITE_INSTANCE_TYPE', 'm1.large')
    v.security_groups =     [env.fetch('BOSH_LITE_SECURITY_GROUP', 'inception')]
    v.subnet_id =           env.fetch('BOSH_LITE_SUBNET_ID') if env.include?('BOSH_LITE_SUBNET_ID')
    v.tags =                tags_from_environment(env)
    v.private_ip_address =  env.fetch('BOSH_LITE_PRIVATE_IP') if env.include?('BOSH_LITE_PRIVATE_IP')
  end

  meta_data_public_ip_url = "http://169.254.169.254/latest/meta-data/public-ipv4"
  meta_data_local_ip_url = "http://169.254.169.254/latest/meta-data/local-ipv4"

  public_ip_code = <<-public_ip_script
public_ip_http_code=`curl -s -o /dev/null -w "%{http_code}" #{meta_data_public_ip_url}`

if [ $public_ip_http_code == "404" ]; then
  local_ip_address=`curl -s #{meta_data_local_ip_url}`
  echo "There is no public IP for this instance"
  echo "The private IP for this instance is $local_ip_address"
  echo "You can 'bosh target $local_ip_address', or run 'vagrant ssh' and then 'bosh target 127.0.0.1'"
else
  public_ip_address=`curl -s #{meta_data_public_ip_url}`
  echo "The public IP for this instance is $public_ip_address"
  echo "You can 'bosh target $public_ip_address', or run 'vagrant ssh' and then 'bosh target 127.0.0.1'"
fi
  public_ip_script

  if Vagrant::VERSION =~ /^1.[0-6]/
    config.vm.provision :shell, id: "public_ip", run: "always", inline: public_ip_code
  else
    config.vm.provision "public_ip", type: :shell, run: "always", inline: public_ip_code
  end

  port_forwarding_code = <<-port_forwarding_script
local_ip=`curl -s #{meta_data_local_ip_url}`
echo "Setting up port forwarding for the CF Cloud Controller..."
sudo iptables -t nat -A PREROUTING -p tcp -d $local_ip --dport 80 -j DNAT --to 10.244.0.34:80
sudo iptables -t nat -A PREROUTING -p tcp -d $local_ip --dport 443 -j DNAT --to 10.244.0.34:443
sudo iptables -t nat -A PREROUTING -p tcp -d $local_ip --dport 4443 -j DNAT --to 10.244.0.34:4443
  port_forwarding_script

  if Vagrant::VERSION =~ /^1.[0-6]/
    config.vm.provision :shell, id: "port_forwarding", run: "always", inline: port_forwarding_code
  else
    config.vm.provision "port_forwarding", type: :shell, run: "always", inline: port_forwarding_code
  end

  cck_code = <<-cck_script
bosh -u admin -p admin target localhost
bosh -u admin -p admin download manifest cf-warden > cf-warden.yml
bosh -u admin -p admin deployment cf-warden.yml


cat <<end | bosh -u admin -p admin cck
2
2
2
2
2
2
2
2
2
2
2
2
yes
end
  cck_script

  if Vagrant::VERSION =~ /^1.[0-6]/
    config.vm.provision :shell, id: "cck", run: "always", inline: cck_code
  else
    config.vm.provision "cck", type: :shell, run: "always", inline: cck_code
  end

  login_code = <<-login_script
    sudo chown -R ubuntu .cf
    sudo chgrp -R ubuntu .cf

    repeat() {
      set +e
      for i in 1 2 3 4 5; do
        "$@"
        if [ $? -eq 0 ] ; then
          break
        fi
        sleep 10
      done
      set -e
    }

    repeat cf api api.10.244.0.34.xip.io --skip-ssl-validation || true
    repeat cf auth admin admin
    repeat cf target -o sample-org -s sample-space

    public_ip_address=`curl -s http://169.254.169.254/latest/meta-data/public-ipv4`

    repeat cf create-domain sample-org spring-music.$public_ip_address.xip.io
    repeat cf map-route spring-music spring-music.$public_ip_address.xip.io
  login_script

  if Vagrant::VERSION =~ /^1.[0-6]/
    config.vm.provision :shell, id: "login", run: "always", inline: login_code
  else
    config.vm.provision "login", type: :shell, run: "always", inline: login_code
  end
end
