#!/bin/bash

yum_server='yum.suixingpay.com'

pkgs=(
'openssh-6.1p1-5.el5.1.x86_64.rpm'
'openssh-server-6.1p1-5.el5.1.x86_64.rpm'
'openssh-clients-6.1p1-5.el5.1.x86_64.rpm'
'libedit0-3.0-1.20090722cvs.el5.x86_64.rpm'
)

for pkg in "${pkgs[@]}"
do
	wget http://${yum_server}/tools/${pkg} -O /tmp/${pkg} || eval "echo Can not download ${pkg}!;exit 1"
done

cd /tmp/

rpm -Uvh ${pkgs[@]} && rm -f ${pkgs[@]}
