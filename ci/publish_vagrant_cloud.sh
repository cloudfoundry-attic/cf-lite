#!/bin/bash

if [ -z "${VAGRANT_CLOUD_ACCESS_TOKEN}" ]; then
  echo "VAGRANT_CLOUD_ACCESS_TOKEN needs to be set"
  exit 1
fi

main(){
  install_tools

  version_id=`create_version`
  upload_box $version_id
  release_version $version_id
}

install_tools() {
  apt-get install -y jq
}

create_version() {
  result=`curl https://vagrantcloud.com/api/v1/box/cloudfoundry/cf-lite/versions \
    -X POST \
    -d version[version]="${GO_PIPELINE_COUNTER}" \
    -d access_token="$VAGRANT_CLOUD_ACCESS_TOKEN"`
  version_id=`echo $result | jq ".number"`

  echo $version_id
}

upload_box() {
  version_id=$1

  curl https://vagrantcloud.com/api/v1/box/cloudfoundry/cf-lite/version/${version_id}/providers \
  -X POST \
  -d provider[name]="virtualbox" \
  -d provider[url]="https://s3.amazonaws.com/cf-lite-build-artifacts/cf-lite-virtualbox-ubuntu-trusty-${GO_PIPELINE_COUNTER}.box" \
  -d access_token="$VAGRANT_CLOUD_ACCESS_TOKEN"
}

release_version() {
  version_id=$1

  curl https://vagrantcloud.com/api/v1/box/cloudfoundry/cf-lite/version/${version_id}/release -X PUT -d access_token="$VAGRANT_CLOUD_ACCESS_TOKEN"
}

main
