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
  # download_box aws ${GO_PIPELINE_COUNTER}
  box_add_and_vagrant_up aws ${GO_PIPELINE_COUNTER}
  # remotely apt-get update
  # remotely apt-get install -y git
  remotely "git clone https://github.com/cloudfoundry/cf-release.git || true && 
            cd cf-release && 
            git checkout v${CF_RELEASE_VERSION} &&
            git submodule update --init --recursive"

  make_config

  remotely "export DEBIAN_FRONTEND=noninteractive &&
            sudo chmod 777 tmp &&
            sudo apt-get -q -y install golang &&
            mkdir go || true &&
            cd cf-release/src/acceptance-tests &&
            export GOPATH=/home/ubuntu/go &&
            export PATH=\$PATH:\$GOPATH/bin &&
            go get -d github.com/cloudfoundry/cf-acceptance-tests || true &&
            export CONFIG=\"/home/ubuntu/integration_config.json\" && 
            cat /home/ubuntu/integration_config.json && 
            env &&
            sudo chmod 777 -R /home/ubuntu/.cf &&
            bin/test"

  # somehow put it on the remote machine
  #remotely "echo \$GOROOT"
  #remotely "echo \$GOPATH"
   # ./bin/add-route || true

  # chruby 2.1.2

  # remotely "export GOPATH=/home/ubuntu/go &&
  #           export PATH=\$PATH:\$GOPATH/bin &&
  #           "
}

remotely() {
  vagrant ssh -c "$@"
}

make_config() {
  remotely "cat > /home/ubuntu/integration_config.json <<EOF
  {
    \"api\": \"api.10.244.0.34.xip.io\",
    \"admin_user\": \"admin\",
    \"admin_password\": \"admin\",
    \"apps_domain\": \"10.244.0.34.xip.io\",
    \"skip_ssl_validation\": true,
    \"default_timeout\": 600,
    \"cf_push_timeout\": 900,
    \"long_curl_timeout\": 910,
    \"broker_start_timeout\": 920
  }
EOF"
}


main

