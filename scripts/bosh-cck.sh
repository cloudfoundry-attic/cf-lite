#!/usr/bin/expect

set timeout 1200

spawn bosh cck

set count 14;
while {$count > 0} {
  expect "Recreate VM using last known apply spec"
  send "2\n"

  set count [expr $count-1];
}

expect "Apply resolutions?"
send "yes\n"

expect eof
