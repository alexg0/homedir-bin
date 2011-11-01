#! /bin/bash

d=~/Downloads/scans
scanner=prn-3rd-fl
me=$(hostname -s|sed s/-//)

mkdir -p $d || exit 1
screen -S dell1600 -d -m -L \
  dell1600n-net-scan.pl \
  --1815dn --multi-session --listen $scanner --name $me \
  --scan-dir $d
