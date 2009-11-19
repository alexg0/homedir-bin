#!/bin/bash

dir=~/vncreflector
cd $dir
if [ -f $dir/PID_FILE.5999 ]; then
   echo killing existing
   kill `cat $dir/PID_FILE.5999`;   
   sleep 2
   kill -9 `cat $dir/PID_FILE.5999`;
   rm $dir/PID_FILE.5999
fi
   
vncreflector -v 6 -p $dir/PASSWD_FILE -l 5999 $dir/HOST_INFO_FILE -t \
              -i $dir/PID_FILE -a $dir/ACTIVE_FILE
