#!/bin/bash

source $(dirname $0)/ci-helpers.sh

set -ex

fetch_latest_bosh() {
  if [ ! -d 'bosh' ]; then
    git clone --depth=1 https://github.com/cloudfoundry/bosh.git
  fi

  (
    cd bosh
    git fetch
    git reset --hard origin/master
    git submodule update --init --recursive
    bundle install
  )
}

box_add_and_vagrant_up() {
  box_type=$1
  candidate_build_number=$2

  vagrant box add cf-lite-${box_type}-ubuntu-trusty-${candidate_build_number}.box --name cf-lite-${box_type}-ubuntu-trusty-${candidate_build_number}.box --force
  vagrant up --provider=virtualbox
}

main() {

  download_box virtualbox ${GO_PIPELINE_COUNTER}
  box_add_and_vagrant_up virtualbox ${GO_PIPELINE_COUNTER}
  ./bin/add-route || true

  fetch_latest_bosh

  echo PATH = $PATH
  which bosh

  echo Running CATS...

  bosh target `vagrant ssh-config 2>/dev/null | grep HostName | awk '{print $2}'`
  bosh -n -u admin -p admin run errand acceptance_tests
}

main
