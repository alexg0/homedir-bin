#! /bin/bash

address=$1

echo $address | mailx -s "test $address test" $address
