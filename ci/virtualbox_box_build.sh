#!/bin/bash

set -ex

download_cf_release() {
  cf_release_version=$1
  cf_tgz=cf-${cf_release_version}.tgz

  if [ ! -e $cf_tgz ]; then
    wget --progress=bar https://s3.amazonaws.com/cf-lite-build-artifacts/$cf_tgz
  fi
}

upload_box() {
  box_type=$1
  candidate_build_number=$2

  box_name=cf-lite-${box_type}-ubuntu-trusty-${candidate_build_number}.box
  bucket_url=s3://cf-lite-ci-pipeline/
  s3cmd --access_key=$BOSH_AWS_ACCESS_KEY_ID --secret_key=$BOSH_AWS_SECRET_ACCESS_KEY put $box_name $bucket_url
}

download_cf_release ${CF_RELEASE_VERSION}
./bin/build-virtualbox
upload_box virtualbox ${GO_PIPELINE_COUNTER}

