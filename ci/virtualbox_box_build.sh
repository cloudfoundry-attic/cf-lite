#!/bin/bash

source $(dirname $0)/ci-helpers.sh

set -ex

./bin/build-virtualbox
upload_box virtualbox ${GO_PIPELINE_COUNTER}

