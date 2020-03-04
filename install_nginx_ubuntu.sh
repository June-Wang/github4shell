#!/bin/bash

tmp_file='/tmp/nginx_signing.key'
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -f ${tmp_file} && rm -f ${tmp_file}" EXIT

curl -s http://nginx.org/keys/nginx_signing.key > ${tmp_file}
test -f ${tmp_file} && sudo apt-key add ${tmp_file}

codename=`lsb_release -cs`
deb_list='/etc/apt/sources.list.d/nginx-stable.list'
test -d /etc/apt/sources.list.d/ &&\
sudo echo "#deb for nginx
deb http://nginx.org/packages/ubuntu/ ${codename} nginx
deb-src http://nginx.org/packages/ubuntu/ ${codename} nginx" > ${deb_list}
test -f /usr/bin/apt-get && sudo /usr/bin/apt-get update||\
eval "echo /usr/bin/apt-get not found!;exit 1"

/usr/bin/apt-get install -y nginx >/dev/null 2>&1 ||\
eval "echo apt-get install -y nginx fail!;exit 1"
#test -f ${deb_list} && ls -lth ${deb_list} && cat ${deb_list}
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable nginx.service
sudo /usr/sbin/nginx -V
