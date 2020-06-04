#! /bin/sh

TT_CB_PL="/home/alexg/bin.shared/totaltalk-callback.pl"
TT_CB_ARGS='-acc 5239264111 -trigger 7510039 -pin 1212'

delay=0
if [ "$1" = "-d" ]; then
	delay=$2;
	shift 2;
fi

# -callback 16504775812 -dest 16505337913 
if [ $# -gt 2 ]; then
	echo "$0 [ cb# [dialto#] ]"
	exit 1
elif [ $# -eq 2 ]; then
	cb=$1
	dest=$2;

	arg="-callback $cb -dest $dest"
elif [ $# -eq 1 ]; then
	# 1 arg means callback
	cb=$1

	arg="-callback $cb"
elif [ $# -eq 0 ]; then
        arg=""
fi

if [ $delay -gt 0 ]; then
	(sleep ${delay}m; 
	 $TT_CB_PL $TT_CB_ARGS $arg -full "Alexander Goldstein" ) &
else
	$TT_CB_PL $TT_CB_ARGS $arg -full "Alexander Goldstein" 
fi

