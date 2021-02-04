#! /bin/sh

ps -f --user $USER|egrep "sshd"|grep -v $$|cut -c9-15|xargs kill
