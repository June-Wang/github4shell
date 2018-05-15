#!/bin/bash

pkg_name="$1"
ftp_url="$2"
ftp_user="$3"
ftp_passwd="$4"

#ip=`/sbin/ip addr list|grep -oP '\d{1,3}(\.\d{1,3}){3}'|grep -Ev '^127|255$|^0|0$'|head -n1`

cd /tmp/ || eval "echo /tmp 文件夹不存在!;exit 1"

which lftp > /dev/null 2>&1 ||\
eval "echo ${ip}服务器未安装lftp命令!;exit 1"

test -f "/tmp/${pkg_name}" && rm -f "/tmp/${pkg_name}"

lftp "${ftp_url}" -u "${ftp_user}","${ftp_passwd}" -e "get ${pkg_name};quit" ||\
eval "echo ${ftp_url}/${pkg_name} 下载失败!;exit 1"

test -f "/tmp/${pkg_name}" &&\
eval "echo ${pkg_name} 已经下载到/tmp/ 文件夹下!"

ls --time-style=long-iso -lth /tmp/${pkg_name} && exit 0 ||\
eval "echo 文件 /tmp/${pkg_name} 不存在!;exit 1"
