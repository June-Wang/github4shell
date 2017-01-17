#!/bin/bash

yum_server='yum.server.local'
pkg='Python-2.7.12.tgz'
YUM_PACKAGE='gcc glibc glibc-common make gcc-c++ zlib zlib-devel readline readline-devel openssl-devel sqlite-devel tcl-devel tk-devel'

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

pkg_path=`echo ${pkg}|sed 's/\.tar\.gz//;s/\.tgz//'`
test -d ${pkg_path} && cd ${pkg_path} || \
eval "echo 未找到${pkg_path};exit 1"

log_file="/tmp/install_${pkg_path}.log"

my_time=`date -d now +"%F_%H-%M"`

echo "${my_time}" > ${log_file}

cmds=(
'./configure --enable-shared'
'make'
'make install'
)

echo "编译安装${pkg_path}"

for shell in "${cmds[@]}"
do
        eval "${shell} >> ${log_file} 2>&1" ||\
        eval "echo ${shell} failed!;exit 1"
done

#test -f /usr/local/lib/libpython2.7.so.1.0 &&
#ln -s /usr/local/lib/libpython2.7.so.1.0 /usr/local/lib/libpython2.7.so ||\
#eval "echo /usr/local/lib/libpython2.7.so.1.0 not found!;exit 1"

test -d /etc/ld.so.conf.d &&\
echo "/usr/local/lib" > /etc/ld.so.conf.d/${pkg_path}.conf ||\
eval "echo /etc/ld.so.conf.d not found!;exit 1"

test -d /etc/profile.d/ &&\
echo 'export PATH=$PATH:/usr/local/bin' > /etc/profile.d/${pkg_path}.sh||\
eval "echo /etc/profile.d/ not found!;exit 1"

pkg='setuptools-1.4.2.tar.gz'

wget -q http://${yum_server}/tools/${pkg} -O ${INSTALL_DIR}/${pkg} ||\
eval "echo wget下载失败;exit 1"

test -d ${INSTALL_DIR} && cd ${INSTALL_DIR}
test -f ${pkg} && tar xzf ${pkg} ||\
eval "echo ${pkg}不存在;exit 1"

pkg_path=`echo ${pkg}|sed 's/\.tar\.gz//;s/\.tgz//'`
test -d ${pkg_path} && cd ${pkg_path} || \
eval "echo 未找到${pkg_path};exit 1"

echo "安装${pkg_path}"

python27='/usr/local/bin/python2.7'
/sbin/ldconfig

test -f ${python27} ||\
eval "echo ${python27} not found!;exit 1"

cmds=(
"${python27} setup.py build"
"${python27} setup.py install"
)

log_file="/tmp/install_${pkg_path}.log"

for shell in "${cmds[@]}"
do
        eval "${shell} >> ${log_file} 2>&1" ||\
        eval "echo ${shell} failed!;exit 1"
done

echo 'OK' && exit 0
