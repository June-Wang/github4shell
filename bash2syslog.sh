#!/bin/bash

test -d /etc/profile.d/ &&\
sudo echo 'PROMPT_COMMAND=$(history -a)
typeset -r PROMPT_COMMAND

function log2syslog
{
   declare command
   command=$BASH_COMMAND
   logger -p local1.notice -t bash2syslog -i -- $USER : $PWD : $command

}
trap log2syslog DEBUG' > /etc/profile.d/rec_his.sh
