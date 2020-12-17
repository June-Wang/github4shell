#!/bin/bash

test -f /usr/bin/rpm ||\
eval "echo not centos!;exit 1"

rpm -qa|grep mariadb-libs >/dev/null 2>&1 &&\
yum remove -y mariadb-libs

file_list=(
mysql-community-common-5.7.32-1.el7.x86_64.rpm
mysql-community-libs-5.7.32-1.el7.x86_64.rpm
mysql-community-client-5.7.32-1.el7.x86_64.rpm
mysql-community-server-5.7.32-1.el7.x86_64.rpm
)

for file in "${file_list[@]}"
do
    test -f ${file} ||\
    eval "echo ${file} not found!;exit 1" &&\
    rpm -ivh ${file}
done

systemctl daemon-reload
systemctl enable mysqld.service
systemctl start  mysqld.service

firewall-cmd --zone=public --add-port=3306/tcp --permanent
firewall-cmd --reload
