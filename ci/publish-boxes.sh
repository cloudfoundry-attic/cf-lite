#!/usr/bin/env bash

set -ex

reset() {
  git reset --hard HEAD
}

trap reset EXIT

create_vagrant_cloud_version(){
  result=`curl https://vagrantcloud.com/api/v1/box/cloudfoundry/cf-lite/versions \
          -X POST \
          -d version[version]="$GO_PIPELINE_COUNTER" \
          -d access_token="$VAGRANT_CLOUD_ACCESS_TOKEN"`
  version_id=`echo $result | jq --raw-output ".number"`

  if [ "$version_id" = "null" ]; then
    echo "Failed to create version"
    exit 1
  fi
  echo $version_id
}

publish_to_s3(){
  for provider in "aws"; do
    publish_vagrant_box_to_s3 $provider $GO_PIPELINE_COUNTER
  done
}

publish_to_vagrant_cloud(){
  version_id=`create_vagrant_cloud_version`

  for provider in "aws"; do
    upload_box_to_vagrant_cloud $provider $provider $version_id
  done

  curl https://vagrantcloud.com/api/v1/box/cloudfoundry/cf-lite/version/${version_id}/release -X PUT -d access_token="$VAGRANT_CLOUD_ACCESS_TOKEN"  
}

update_vagrant_file() {
  sed -i'' -e "s/config.vm.box_version = '.\{4\}'/config.vm.box_version = '$GO_PIPELINE_COUNTER'/" Vagrantfile
  git diff
  git add Vagrantfile
  git commit -m "Update box version to $GO_PIPELINE_COUNTER"
  git remote rm origin
  git remote add origin 'git@github.com:cloudfoundry/cf-lite.git'
  git push origin HEAD:develop
}

upload_box_to_vagrant_cloud() {
  provider=$1
  box_type=$2
  version_id=$3

  curl https://vagrantcloud.com/api/v1/box/cloudfoundry/cf-lite/version/${version_id}/providers \
  -X POST \
  -d provider[name]="$provider" \
  -d provider[url]="https://s3.amazonaws.com/cf-lite-boxes/cf-lite-$box_type-ubuntu-trusty-$GO_PIPELINE_COUNTER.box" \
  -d access_token="$VAGRANT_CLOUD_ACCESS_TOKEN"

  # -d provider[url]="http://d2u2rxhdayhid5.cloudfront.net/cf-lite-$box_type-ubuntu-trusty-$GO_PIPELINE_COUNTER.box" \
}

publish_vagrant_box_to_s3() {
  box_type=$1
  candidate_build_number=$2
  box_name="cf-lite-${box_type}-ubuntu-trusty-${candidate_build_number}.box"

#  s3cmd --access_key=$BOSH_AWS_ACCESS_KEY_ID --secret_key=$BOSH_AWS_SECRET_ACCESS_KEY mv s3://cf-lite-ci-pipeline/$box_name s3://cf-lite-boxes/$box_name
  s3cmd mv s3://cf-lite-ci-pipeline/$box_name s3://cf-lite-boxes/$box_name
}

main(){
  if [ -z "${VAGRANT_CLOUD_ACCESS_TOKEN}" ]; then
    echo "VAGRANT_CLOUD_ACCESS_TOKEN needs to be set"
    exit 1
  fi
  
  publish_to_s3
  publish_to_vagrant_cloud
  #update_vagrant_file
}

main
