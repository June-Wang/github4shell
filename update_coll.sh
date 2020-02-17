#!/bin/bash

test -f /etc/graylog/collector-sidecar/collector_sidecar.yml &&\
service collector-sidecar stop ||\
exit


mydate=`date -d now +"%F_%H-%M-%S"`
cp /etc/graylog/collector-sidecar/collector_sidecar.yml /etc/graylog/collector-sidecar/collector_sidecar.yml.${mydate}

pkg_url='https://github.com/Graylog2/collector-sidecar/releases/download/0.1.8/collector-sidecar_0.1.8-1_amd64.deb'
tmp_file='/tmp/collector-sidecar.deb'

trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -f ${tmp_file} && rm -f ${tmp_file}"  EXIT

wget ${pkg_url} -O /tmp/collector-sidecar.deb ||\
eval "echo download ${pkg_url} fail!;exit 1"

test -f ${tmp_file} &&\
sudo /usr/bin/dpkg -i ${tmp_file}

test -f /usr/bin/graylog-collector-sidecar
#sudo /usr/bin/graylog-collector-sidecar -service install
sudo systemctl enable collector-sidecar.service
service collector-sidecar restart
