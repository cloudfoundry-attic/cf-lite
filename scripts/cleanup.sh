#!/bin/bash


main(){
  rm -rf /var/vcap/store/cpi/ephemeral_bind_mounts_dir
  rm -rf /var/vcap/store/cpi/persistent_bind_mounts_dir

  rm -rf /home/vagrant
}

main
