#!/bin/bash

source $(dirname $0)/ci-helpers.sh

set -e -x

box_version=$(cat box-version/number)

cd cf-lite

export AWS_ACCESS_KEY_ID=$BOSH_AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$BOSH_AWS_SECRET_ACCESS_KEY

./bin/build-aws ${BOSH_LITE_AMI} ${CF_RELEASE_VERSION} $box_version | tee output

ami=`tail -2 output | grep -o "ami-.*"`

sleep 60

aws ec2 modify-image-attribute --image-id $ami --launch-permission "{\"Add\": [{\"Group\":\"all\"}]}"

upload_box aws $box_version
