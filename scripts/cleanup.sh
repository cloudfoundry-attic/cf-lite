#!/bin/bash


main(){
  unmount_loop_devices
  delete_bind_mount_dirs
  delete_workspace
}

unmount_loop_devices() {
  sudo apt-get install -y curl
  sudo apt-get install -y jq

  containers=`curl 127.0.0.1:7777/containers | jq '.handles'`
  echo $containers
  let num_containers=`echo $containers | jq 'length'` i=1
  echo $num_containers
  while (($i <= $num_containers)); do
    container_id=`echo $containers | jq ".[$i]"`
    echo $container_id
    loopback=`df | grep $container_id | awk "{ print $1 }"`

    if [ $? = 0 ]; then
      which umount
      echo $loopback
      if [ ! -Z $loopback ]; then
        umount $loopback
      fi
    fi

    let i++
  done
}

delete_bind_mount_dirs() {
  rm -rf /var/vcap/store/cpi/ephemeral_bind_mounts_dir
  rm -rf /var/vcap/store/cpi/persistent_bind_mounts_dir
}

delete_workspace() {
  # Remove everything except for hidden files and the cf-manifest,
  # which are needed to run bosh cck
  for file in `ls ${HOME}`; do
    rm -rf `find ${HOME}/${file} -type f ! -name cf-manifest.yml`
  done
}

main
