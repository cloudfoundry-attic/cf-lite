#!/bin/bash

set -ex

fetch_bosh_lite_ovf(){
  full_path=`pwd "$(dirname $0)/.."`
  mkdir -p tmp

  (
    cd tmp
    rm -f virtualbox.box

    wget https://vagrantcloud.com/cloudfoundry/boxes/bosh-lite/versions/6/providers/virtualbox.box 
    tar xf virtualbox.box
  )

  echo "${full_path}/tmp/box.ovf"
}

main() {
  ovf_file=`fetch_bosh_lite_ovf`

  template_path=$(dirname $0)/../templates/virtualbox.json
  packer build -var "source_path=${ovf_file}" $template_path
}

main
