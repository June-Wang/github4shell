#!/bin/bash

yum_server='yum.server.local'
pkg='node-v6.10.1-linux-x64.tar.gz'
install_path='/usr/local'

test -d ${install_path}/nodejs &&\
eval "echo nodejs 已经安装!;exit 1"

temp_dir="/tmp/nodejs.$$"
test -d ${temp_dir} || mkdir -p ${temp_dir} 

trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -d ${temp_dir} && rm -rf ${temp_dir}"  EXIT

test -d ${install_path} || mkdir -p ${install_path}

test -d ${temp_dir} && cd ${temp_dir}

curl -O -L http://${yum_server}/tools/${pkg} ||\
eval "echo 下载安装包失败!;exit 1"

pkg_dir=`echo ${pkg}|sed -r 's|.tar.gz||'`
tar xzf ${pkg} &&\
mv ${pkg_dir} ${install_path}/

test -d ${install_path}/${pkg_dir} &&\
ln -s ${install_path}/${pkg_dir} ${install_path}/nodejs &&\
chown root.root -R ${install_path}/${pkg_dir}

test -d /etc/profile.d &&\
echo "export NODE_HOME=${install_path}/nodejs
export PATH=\$PATH:\$NODE_HOME/bin  
export NODE_PATH=\$NODE_HOME/lib/node_modules
" > /etc/profile.d/nodejs.sh &&\
eval "echo 安装完毕!;exit 0"
