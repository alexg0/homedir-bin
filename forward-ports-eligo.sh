#! /bin/bash

ssh_server=alexg@serv01.eligoenergy.com
ssh_server=serv01.eligoenergy.com

autossh_args="-f"
ssh_args="-C -N"

local=("-L 54323:whdb.eligoenergy.com:5432"
       "-L 54324:whdb.eligoenergy.com:5432"
       "-c 3des -D 8527"
       )

all_ports="${local[*]}"

AUTOSSH_PORT=27027 autossh ${autossh_args} ${all_ports} ${ssh_server} ${ssh_args}

