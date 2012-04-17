#! /bin/bash

d=~/Downloads/scans
scanner=prn-3rd-fl
me=$(hostname -s|sed s/-//)

mkdir -p $d || exit 1
screen -ls | grep dell1600 && \
    echo "Already running, not starting." || \
    screen -S dell1600 -d -m \
         dell1600n-net-scan.pl \
  	  --1815dn --multi-session --listen $scanner --name $me \
          --scan-dir $d

echo "Scan daemon status:"
screen -ls | grep dell1600
