#!/bin/bash

YUM_SERVER='yum.server.local'
PACKAGE_URL="http://${YUM_SERVER}/tools"

INSTALL_PATH="/tmp/tmp.$$"
TMP_FILE="${INSTALL_PATH}/tmpfile.$$"

#SET EXIT STATUS AND COMMAND
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -rf ${INSTALL_PATH}"  EXIT

check_platform (){
local platform_info=`uname -m`
local platform=''
echo ${platform_info}|grep '64' >/dev/null 2>&1 && platform='x64' || platform='x86'
echo "${platform}"
}

platform=`check_platform`
if [ "${platform}" == "x86" ];then
        echo "This pkgs not support x86!"
        exit 1
fi

SYSTEM_INFO=`head -n 1 /etc/issue`
case "${SYSTEM_INFO}" in
        'CentOS release 5'*)
                ;;
        'Red Hat Enterprise Linux Server release 5'*)
                ;;
        *)
        echo "This script not support ${SYSTEM_INFO}" 1>&2
                exit 1
        ;;
esac

packages=(
python26-zmq-14.3.1-3.el5.x86_64.rpm
zeromq-4.0.4-2.el5.x86_64.rpm
)
test -d ${INSTALL_PATH} || mkdir -p ${INSTALL_PATH}

for package in "${packages[@]}"
do
        wget http://${YUM_SERVER}/rpm/${package} -O ${INSTALL_PATH}/${package} && echo -en "${package} " >> ${TMP_FILE}
done

pkg=`cat ${TMP_FILE}`
if [ -z "${pkg}" ];then
        exit 0
else
        rpm -Uvh ${pkg}
        test -f /etc/init.d/salt-minion && /etc/init.d/salt-minion restart
        echo "$pkg has been installted!" && exit 0
fi
