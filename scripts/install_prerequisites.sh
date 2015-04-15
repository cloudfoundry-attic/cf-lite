#!/bin/bash
set -ex

sudo apt-get -y install awscli
sudo apt-get -y install s3cmd

# we've stored the s3cmd config file (.s3cfg) in /var/vcap/data (the persistent disk).  if this is somehow gone, you can recreate it by running s3cmd --configure and copying ~vcap/.s3cfg to /root
sudo cp /var/vcap/data/.s3cfg ~vcap
sudo cp /var/vcap/data/.s3cfg /root

set +e
# this is where the script looks for the private key
mkdir ~vcap/.ssh
sudo mkdir /root/.ssh

set -e

# we copied the private key to the persistent disk at /var/vcap/data
# if for some reason it's gone, it should be on dx191 in ~/workspace/cf-lite as id_rsa_cf_lite
# it matches the cf-lite public key in AWS EC2 Key Pairs
sudo cp /var/vcap/data/id_rsa_cf_lite ~vcap/.ssh
sudo cp /var/vcap/data/id_rsa_cf_lite /root/.ssh


# the default goCD agent behaviour is to set the BOSH_LITE_PRIVATE_IP variable
# we don't want to do this for our CF-Lite AWS account, it works only when it's not set
# this comments out the line that sets that variable in the vagrant wrapper script
sudo mv /var/vcap/packages/vagrant-1.6.5/wrapper/vagrant /var/vcap/packages/vagrant-1.6.5/wrapper/vagrant-old
sudo sed "s/export BOSH_LITE_PRIVATE_IP/#export BOSH_LITE_PRIVATE_IP/" < /var/vcap/packages/vagrant-1.6.5/wrapper/vagrant-old > tmp-vagrant
sudo mv tmp-vagrant /var/vcap/packages/vagrant-1.6.5/wrapper/vagrant
sudo chmod 744 /var/vcap/packages/vagrant-1.6.5/wrapper/vagrant
