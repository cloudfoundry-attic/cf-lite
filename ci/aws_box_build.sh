#!/bin/bash

set -ex

upload_box() {
  box_type=$1
  candidate_build_number=$2

  box_name=cf-lite-${box_type}-ubuntu-trusty-${candidate_build_number}.box
  bucket_url=s3://cf-lite-ci-pipeline/
  s3cmd --access_key=$BOSH_AWS_ACCESS_KEY_ID --secret_key=$BOSH_AWS_SECRET_ACCESS_KEY put $box_name $bucket_url
}

./bin/build-aws ${BOSH_LITE_AMI} ${CF_RELEASE_VERSION} ${GO_PIPELINE_COUNTER}

ami=`tail -2 output | grep -Po "ami-.*"`

sleep 60
aws ec2 modify-image-attribute --image-id $ami --launch-permission "{\"Add\": [{\"Group\":\"all\"}]}"
upload_box aws ${GO_PIPELINE_COUNTER}

