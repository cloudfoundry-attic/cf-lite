#!/bin/bash

set timeout 1200

bosh -u admin -p admin target localhost
bosh -u admin -p admin download manifest cf-warden > cf-warden.yml
bosh -u admin -p admin deployment cf-warden.yml

cat <<END | bosh -u admin -p admin cck
2
2
2
2
2
2
2
2
2
2
2
2
2
2
yes
END