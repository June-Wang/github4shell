#!/bin/bash

#包名
pkg='pinpoint-agent-2.2.0.tar.gz'
#安装路径
path='/usr/local'
#日志服务器ip
log_server='192.168.100.129'

test -f ${pkg} ||\
eval "echo ${pkg} not found!;exit 1"

test -d ${path} ||\
mkdir -p ${path}

test -f ${pkg} &&\
tar xzf ${pkg} -C ${path}/

pkg_path=`echo ${pkg}|sed 's/.tar.gz//'`

test -d ${path}/pinpoint-agent ||\
ln -s ${path}/${pkg_path} ${path}/pinpoint-agent

test -f ${path}/pinpoint-agent/pinpoint.config ||\
cp pinpoint-springboot.config ${path}/pinpoint-agent/pinpoint.config 
#mv ${path}/pinpoint-agent/pinpoint-root.config ${path}/pinpoint-agent/pinpoint.config
test -f ${path}/pinpoint-agent/pinpoint.config &&\
sed -i "s/ip=127.0.0.1/ip=${log_server}/g" ${path}/pinpoint-agent/pinpoint.config 

echo "vi ${path}/pinpoint-agent/pinpoint.config

detail:
cd ${path}/pinpoint-agent/profiles

add:
-javaagent:${path}/pinpoint-agent/pinpoint-bootstrap.jar -Dpinpoint.agentId=app01 -Dpinpoint.applicationName=app-name"
