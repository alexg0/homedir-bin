#!/bin/bash

# droppid v0.2.3
# Public Domain Mark 1.0
# https://gist.github.com/idleberg/81ed196f2401be045893
#
# Usage: sudo [sh] droppid.sh [priority]

# Check for sudo
if [ "$EUID" -ne 0 ]; then
  echo "Error: Permission denied, please run with administrator rights"
  exit 1
fi

priority=$1
dropbox="~/Library/Application Support/Dropbox/Dropbox.app/Contents/MacOS/Dropbox"

if [[ $priority =~ ^-?[0-9]+$ && $priority -ge "-20" && $priority -le "20"  ]]; then

    # Get Dropbox process ID
    pid=$(ps -Ac -o pid,comm | awk '/^ *[0-9]+ Dropbox$/ {print $1}')

    # Check if Dropbox is running
    if [[ -z $pid ]]; then
        echo "Dropbox doesn't seem to be running"
        echo "Launching Dropbox with a priority of $pid"
        
        # Launch process with priority
        nice -n $priority $dropbox
    else
        echo "Dropbox is currently using PID #$pid"
        echo "Setting priority to $priority"

        # Set priority of process
        renice -n $priority -p $pid
    fi
else
    # Invalid or missing argument
    echo "Error: Priority needs to be an integer between -20 and 20 ($p)"
    exit 1
fi

# Game over
echo "Completed."
exit 0