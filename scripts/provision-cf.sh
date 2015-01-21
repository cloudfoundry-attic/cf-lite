#!/bin/bash

set -xe

STEMCELL_SOURCE=http://bosh-warden-stemcells.s3.amazonaws.com
STEMCELL_FILE=latest-bosh-stemcell-warden.tgz
WORKSPACE_DIR="${HOME}/tmp"
CF_DIR="${WORKSPACE_DIR}/cf-release"
BOSH_LITE_DIR="${WORKSPACE_DIR}/bosh-lite"

main() {
  make_compiled_package_cache
  change_tmpdir
  fetch_stemcell
  upload_stemcell
  update_apt_get
  install_tools
  build_manifest
  deploy_release
  delete_compiled_package_cache
}

make_compiled_package_cache() {
  mkdir -p /vagrant/tmp/compiled_package_cache
  chmod -R 777 /vagrant/tmp/compiled_package_cache
}

delete_compiled_package_cache() {
  rm -rf /vagrant
}

change_tmpdir() {
  export TMPDIR=${WORKSPACE_DIR}
  (cat <<PROFILE
export TMPDIR=${WORKSPACE_DIR}
PROFILE
) >> $HOME/.profile
}

fetch_stemcell() {
  wget "${STEMCELL_SOURCE}/${STEMCELL_FILE}"
}

upload_stemcell() {
  bosh -n -u admin -p admin upload stemcell ${STEMCELL_FILE} --skip-if-exists
}

update_apt_get(){
  apt-get -y update
}

install_tools(){
  (
    cd $WORKSPACE_DIR
    apt-get -y install git
    apt-get -y install unzip
    wget https://github.com/cloudfoundry-incubator/spiff/releases/download/v1.0.3/spiff_linux_amd64.zip
    unzip spiff_linux_amd64.zip
    cp spiff /usr/local/bin/spiff
  )
}

build_manifest() {
  (
    cd $WORKSPACE_DIR
    git clone https://github.com/cloudfoundry/cf-release.git
    cd $CF_DIR
    git checkout tags/v${CF_RELEASE_VERSION}

    cd $WORKSPACE_DIR
    git clone --depth=1 https://github.com/cloudfoundry/bosh-lite.git
    cd $BOSH_LITE_DIR
    export CF_RELEASE_DIR=$CF_DIR
    ./bin/make_manifest_spiff
  )
}

deploy_release() {
  bosh -n -u admin -p admin upload release --skip-if-exists https://bosh.io/d/github.com/cloudfoundry/cf-release?v=${CF_RELEASE_VERSION}.tgz
  bosh -n -u admin -p admin deploy
}

main

