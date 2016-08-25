#!/bin/bash

yum_server='yum.server.local'
pkg='nginx-1.6.3.tar.gz'
YUM_PACKAGE='gcc gcc-c++ openssl openssl-devel glib2-devel pcre-devel bzip2-devel'

#SET TEMP DIR
INSTALL_DIR="/tmp/install_$$"

#SET EXIT STATUS AND COMMAND
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -d ${INSTALL_DIR} && rm -rf ${INSTALL_DIR}"  EXIT

ls /usr/bin/yum >/dev/null 2>&1 ||\
eval "echo 未安装yum!;exit 1"

yum --skip-broken --nogpgcheck install -y ${YUM_PACKAGE} >/dev/null 2>&1 ||\
eval "echo yum安装失败;exit 1"

test -d ${INSTALL_DIR} || mkdir -p ${INSTALL_DIR}
wget -q http://${yum_server}/tools/${pkg} -O ${INSTALL_DIR}/${pkg} ||\
eval "echo wget下载失败;exit 1"

test -d ${INSTALL_DIR} && cd ${INSTALL_DIR}
test -f ${pkg} && tar xzf ${pkg} ||\
eval "echo ${pkg}不存在;exit 1"

pkg_path=`echo ${pkg}|sed 's/\.tar\.gz//'`
test -d ${pkg_path} && cd ${pkg_path} || \
eval "echo 未找到${pkg_path};exit 1"

./configure --prefix=/usr/local/nginx >/dev/null 2>&1 || \
eval "编译失败;exit 1"
make > /dev/null 2>&1 && make install >/dev/null 2>&1

useradd -s /sbin/nologin nginx
ln -sf /usr/local/nginx/sbin/nginx  /usr/sbin

nginx -t
