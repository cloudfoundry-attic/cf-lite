#!/bin/bash

source $(dirname $0)/ci-helpers.sh

set -e -x

scripts/install_prerequisites.sh

./bin/build-aws ${BOSH_LITE_AMI} ${CF_RELEASE_VERSION} ${GO_PIPELINE_COUNTER} | tee output

ami=`tail -2 output | grep -o "ami-.*"`

sleep 60
aws ec2 modify-image-attribute --image-id $ami --launch-permission "{\"Add\": [{\"Group\":\"all\"}]}"
upload_box aws ${GO_PIPELINE_COUNTER}
