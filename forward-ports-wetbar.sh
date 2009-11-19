#! /bin/bash

ssh_server=tiger.barsook.com
ssh_server_cg=wetbar.checkgiant.com

local_imap="-L 9143:localhost:143"
local_smtp="-L 9025:localhost:25"
local_p4="-L 9666:localhost:1666"
local_vnc="-L 5930:localhost:5930 -L 5931:localhost:5931 -L 5932:localhost:5932 -L 5939:locahost:5939"
local_vncref="-L 5999:localhost:5999 -L 5510:localhost:5510"

ports1="${local_imap} ${local_p4} ${local_smtp}"
ports2="${local_vnc} ${remote_vnc}"
all_ports="${ports1} ${ports2}"

# autossh -N -f -l alexg ${all_ports} ${ssh_server}

local_ssh_wetbar="-L2022:bullwinkle:22"
local_vnc_wetbar="-L5921:bullwinkle:5901 -L5922:bullwinkle:5902 -L5931:devdb02:5901 -L5932:devdb02:5902"
ports_wetbar1="${local_ssh_wetbar} ${local_vnc_wetbar}"
all_ports_cg="${ports_wetbar1}"

autossh -l alexg ${all_ports_cg} ${ssh_server_cg}
