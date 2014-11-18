#!/bin/bash

set -xe

STEMCELL_SOURCE=http://bosh-jenkins-artifacts.s3.amazonaws.com/bosh-stemcell/warden
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
    git clone --depth=1 https://github.com/cloudfoundry/cf-release.git
    cd $CF_DIR

    cd $WORKSPACE_DIR
    git clone --depth=1 https://github.com/cloudfoundry/bosh-lite.git
    cd $BOSH_LITE_DIR
    export CF_RELEASE_DIR=$CF_DIR
    ./bin/make_manifest_spiff
  )
}

deploy_release() {
  MOST_RECENT_CF_RELEASE=$(find ${CF_DIR}/releases -regex ".*cf-[0-9]*.yml" | sort | tail -n 1)
  bosh -n -u admin -p admin upload release --skip-if-exists $MOST_RECENT_CF_RELEASE
  bosh -n -u admin -p admin deploy
}

main

