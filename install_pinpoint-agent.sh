#!/bin/bash

pkg='pinpoint-agent-2.2.0.tar.gz'
path='/usr/local'

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
cp pinpoint-springboot.config ${path}/pinpoint-agent/
#mv ${path}/pinpoint-agent/pinpoint-root.config ${path}/pinpoint-agent/pinpoint.config

echo "vi ${path}/pinpoint-agent/pinpoint.config

detail:
cd ${path}/pinpoint-agent/profiles

add:
-javaagent:${path}/pinpoint-agent/pinpoint-bootstrap.jar -Dpinpoint.agentId=app01 -Dpinpoint.applicationName=app-name"
