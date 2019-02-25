#!/bin/bash

url='https://packages.graylog2.org/repo/packages/graylog-2.5-repository_latest.deb'
file=`echo ${url}|awk -F'/' '{print $NF}'`
tmp_deb="/tmp/${file}"
#exit
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -f ${tmp_deb} && rm -f ${tmp_deb}" EXIT
wget ${url} -O ${tmp_deb}
sudo dpkg -i ${tmp_deb}
sudo apt-get update && sudo apt-get install graylog-server
sudo systemctl daemon-reload
sudo systemctl enable graylog-server.service
#sudo systemctl start graylog-server.service
