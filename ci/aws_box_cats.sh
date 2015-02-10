#!/bin/bash

set -ex

main() {
  echo Running CATS...
  bosh -n -u admin -p admin run errand acceptance_tests
}

main

