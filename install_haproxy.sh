#!/bin/bash

yum_server='yum.server.local'
YUM_PACKAGE='haproxy zlib-devel make gcc gcc++ pcre-devel openssl-devel'

#SET TEMP DIR
INSTALL_DIR="/tmp/install_$$"

#SET EXIT STATUS AND COMMAND
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "test -d ${INSTALL_DIR} && rm -rf ${INSTALL_DIR}"  EXIT

ls /usr/bin/yum >/dev/null 2>&1 ||\
eval "echo 未安装yum!;exit 1"

yum --skip-broken --nogpgcheck install -y ${YUM_PACKAGE} > /tmp/yum.log 2>&1 ||\
eval "echo yum安装失败!日志请查看: /tmp/yum.log ;exit 1"

download_pkg () {
local pkg="$1"
local url="http://${yum_server}/tools/${pkg}"
test -d ${INSTALL_DIR} || mkdir -p ${INSTALL_DIR}
wget -q ${url} -O ${INSTALL_DIR}/${pkg} ||\
eval "echo wget ${url} 下载失败;exit 1"
}

decompress_pkg () {
local pkg="$1"
test -d ${INSTALL_DIR} && cd ${INSTALL_DIR}
test -f ${pkg} && tar xzf ${pkg} ||\
eval "echo ${pkg}不存在;exit 1"
}

pkg_path () {
local pkg="$1"
local pkg_dir=`echo ${pkg}|sed 's/\.tar\.gz//'`
echo "${INSTALL_DIR}/${pkg_dir}"
}

cd_to_path () {
local pkg_path="$1"
test -d ${pkg_path} && cd ${pkg_path} || \
eval "echo 未找到${pkg_path};exit 1"
}

#install haproxy
pkg='haproxy-1.5.18.tar.gz'
download_pkg "${pkg}"
decompress_pkg "${pkg}"
pkg_path=`pkg_path "${pkg}"`
cd_to_path "${pkg_path}"

target=`uname -r|grep -oP '^.{3}'|head -n1|sed 's/\.//'`

id haproxy >/dev/null 2>&1||\
useradd -M -s /sbin/nologin haproxy

make TARGET=linux${target} USE_ZLIB=yes USE_OPENSSL=1 USE_PCRE=1 PREFIX=/usr/local/haproxy > /tmp/install_${pkg}.log 2>&1 &&
make install PREFIX=/usr/local/haproxy >> /tmp/install_${pkg}.log 2>&1 ||\
eval "echo ${pkg} 编译失败!请查看日志: /tmp/install_${pkg}.log;exit 1"

test -f /usr/sbin/haproxy &&\
mv /usr/sbin/haproxy /usr/sbin/haproxy.old

test -f /usr/local/haproxy/sbin/haproxy &&\
ln -s /usr/local/haproxy/sbin/haproxy /usr/sbin/haproxy

haproxy -v|head -n1
