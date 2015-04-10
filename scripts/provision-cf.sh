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
  change_cf_permissions
  remove_ssh_authorized_keys
}

change_cf_permissions() {
  chown -R ubuntu /home/ubuntu/
  chgrp -R ubuntu /home/ubuntu/
}

remove_ssh_authorized_keys()
{
  rm /root/.ssh/authorized_keys
  rm /home/ubuntu/.ssh/authorized_keys
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
    git submodule update --init --recursive

    sed s#'"artifacts_directory": "/var/vcap/sys/log/acceptance_tests/",'#'"artifacts_directory": "/var/vcap/sys/log/acceptance_tests/",\n  "default_timeout": 180,\n  "cf_push_timeout": 270,\n  "long_curl_timeout": 360,\n  "broker_start_timeout": 360,'# < $CF_DIR/jobs/acceptance-tests/templates/config.json.erb > $CF_DIR/jobs/acceptance-tests/templates/config.json.new
    mv $CF_DIR/jobs/acceptance-tests/templates/config.json.erb $CF_DIR/jobs/acceptance-tests/templates/config.json.old
    mv $CF_DIR/jobs/acceptance-tests/templates/config.json.new $CF_DIR/jobs/acceptance-tests/templates/config.json.erb

    cd $WORKSPACE_DIR
    git clone --depth=1 https://github.com/cloudfoundry/bosh-lite.git
    cd $BOSH_LITE_DIR
    export CF_RELEASE_DIR=$CF_DIR
    ./bin/make_manifest_spiff

    sed s/"apps_domain: 10.244.0.34.xip.io"/"apps_domain: 10.244.0.34.xip.io\n    default_timeout: 180\n    cf_push_timeout: 360\n    long_curl_timeout: 360\n    broker_start_timeout: 300"/ < /home/ubuntu/tmp/bosh-lite/manifests/cf-manifest.yml > /home/ubuntu/tmp/bosh-lite/manifests/cf-manifest-new.yml
    mv /home/ubuntu/tmp/bosh-lite/manifests/cf-manifest.yml /home/ubuntu/tmp/bosh-lite/manifests/cf-manifest-old.yml
    mv /home/ubuntu/tmp/bosh-lite/manifests/cf-manifest-new.yml /home/ubuntu/tmp/bosh-lite/manifests/cf-manifest.yml
  )
}

deploy_release() {
  wget -O cf-${CF_RELEASE_VERSION}.tgz https://bosh.io/d/github.com/cloudfoundry/cf-release?v=${CF_RELEASE_VERSION}
  bosh -n -u admin -p admin upload release --skip-if-exists cf-${CF_RELEASE_VERSION}.tgz
  bosh -n -u admin -p admin deploy
}

main

