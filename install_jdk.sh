#!/bin/bash

yum_server='192.168.29.234'
local_path='/usr/local'

usage (){
	program_name=`basename $0`
	echo "Usage: ./${program_name} [ 5|1.5|6|1.6 ]" 1>&2
	exit 1
}

if [ $# -ne 1 ];then
	usage
else
	echo "$1"|grep -oE '5|1.5|6|1.6' >/dev/null 2>&1 && jdk_version="$1" || usage
fi

platform_info=`uname -m`
echo ${platform_info}|grep '64' >/dev/null 2>&1 && platform='x64' || platform='x86'

case "${jdk_version}" in
        6|1.6)
		jdk_path='jdk1.6.0_37'
                ;;
        5|1.5)
		jdk_path='jdk1.5.0_22'
                ;;
        *)
                echo "This script not support jdk ${jdk_version}" 1>&2
                exit 1
                ;;
esac

jdk_file="${jdk_path}-${platform}.tar.gz"
download_file="http://${yum_server}/tools/${jdk_file}"

test -d ${local_path} && cd ${local_path} || eval "echo ${local_path} not exsit! 1>&2;exit 1"

echo -n "download ${download_file} ..."
wget -q ${download_file} && echo "done." || eval "echo ${download_file} not exsit! 1>&2;exit 1"

test -d "${local_path}/${jdk_path}" && rm -rf "${local_path}/${jdk_path}"
echo -n "install ${jdk_path} ..."
test -e ${jdk_file} && tar xzf ${jdk_file}
rm -f ${jdk_file} && echo "done."

env_file='/etc/profile.d/java_env.sh'
echo "export JAVA_HOME=${local_path}/${jdk_path}
export CLASSPATH=\$CLASSPATH:\$JAVA_HOME/lib:\$JAVA_HOME/jre/lib
export PATH=\$JAVA_HOME/bin:\$JAVA_HOME/jre/bin:\$PATH" > ${env_file}
test -e ${env_file} && source ${env_file}
echo "${jdk_path} has been installed!" && exit 0
