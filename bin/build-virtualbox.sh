#!/bin/bash

set -ex

FULL_PATH=`pwd "$(dirname $0)/.."`

fetch_bosh_lite_ovf(){
  mkdir -p tmp

  (
    cd tmp
    rm -f virtualbox.box

    wget https://vagrantcloud.com/cloudfoundry/boxes/bosh-lite/versions/6/providers/virtualbox.box 
    tar xf virtualbox.box
  )

  echo "${FULL_PATH}/tmp/box.ovf"
}

set_virtualbox_home(){
  VBoxManage setproperty machinefolder "/var/vcap/data/VirtualBox\ VMs"
}

main() {
  set_virtualbox_home
  ovf_file=`fetch_bosh_lite_ovf`

  template_path="${FULL_PATH}/templates/virtualbox.json"
  ./packer build -var "source_path=${ovf_file}" -var "build_number=${GO_PIPELINE_COUNTER}" $template_path
}

main
