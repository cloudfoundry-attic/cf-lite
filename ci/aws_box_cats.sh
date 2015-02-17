#!/bin/bash

source $(dirname $0)/ci-helpers.sh

set -ex

box_add_and_vagrant_up() {
  box_type=$1
  candidate_build_number=$2

  vagrant box add cf-lite-${box_type}-ubuntu-trusty-${candidate_build_number}.box --name cf-lite --force
  vagrant up --provider=aws
}

main() {

  download_box aws ${GO_PIPELINE_COUNTER}
  box_add_and_vagrant_up aws ${GO_PIPELINE_COUNTER}
  ./bin/add-route || true

  echo PATH = $PATH
  which bosh

  echo Running CATS...

  bosh -n -u admin -p admin target `vagrant ssh-config 2>/dev/null | grep HostName | awk '{print $2}'`
  bosh -n -u admin -p admin download manifest cf-warden > cf-warden.yml
  bosh -n -u admin -p admin deployment cf-warden.yml
  bosh -n -u admin -p admin run errand acceptance_tests
}

main
