#!/bin/bash

main(){
  install_tools
  upload_box_to_s3
}

install_tools() {
  apt-get install python-dateutil
  wget https://github.com/s3tools/s3cmd/archive/v1.5.0-rc1.tar.gz
  tar xf v1.5.0-rc1.tar.gz
}

upload_box_to_s3() {
  # Assumes there is only one box in the working directory
  ./s3cmd-1.5.0-rc1/s3cmd put -P --progress cf-lite-virtualbox-ubuntu-trusty-${GO_PIPELINE_COUNTER}.box s3://cf-lite-build-artifacts/
}

main
