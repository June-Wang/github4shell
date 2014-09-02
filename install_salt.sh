#!/bin/bash

#SET ENV
YUM_SERVER='yum.lefu.local'
PACKAGE_URL="http://${YUM_SERVER}/tools"

#SET TEMP PATH
TEMP_PATH='/usr/local/src'

#SET TEMP DIR
INSTALL_DIR="install_$$"
INSTALL_PATH="${TEMP_PATH}/${INSTALL_DIR}"

#SET PACKAGE
YUM_PACKAGE='gcc glibc glibc-common make cmake gcc-c++'
APT_PACKAGE='build-essential libtool python python-dev python-jinja2 python-yaml m2crypto'

#SET EXIT STATUS AND COMMAND
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -rf ${INSTALL_PATH}"  EXIT

download_func () {
local func_shell='func4install.sh'
local func_url="http://${YUM_SERVER}/shell/${func_shell}"
local tmp_file="/tmp/${func_shell}"

wget -q ${func_url} -O ${tmp_file} && source ${tmp_file} ||\
eval "echo Can not access ${func_url}! 1>&2;exit 1"
rm -f ${tmp_file}
}

main () {
#DOWNLOAD FUNC FOR INSTALL
download_func

#CHECK SYSTEM AND CREATE TEMP DIR
check_system
#create_tmp_dir
set_install_cmd 'lan'

#http server
url="http://${YUM_SERVER}/shell"

files=(
install_libzmq.sh
install_pyzmq.sh
install_pycrypto.sh
install_msgpack-python.sh
)

for file in "${files[@]}"
do
	download_exec "${file}"
done

#Install salt-2014.1.10.tar.gz
PACKAGE='salt-2014.1.10.tar.gz'
create_tmp_dir
download_and_check
run_cmds '/usr/bin/python setup.py install'

#salt setting
ln -s /usr/local/bin/salt-* /usr/bin/
mkdir -p /etc/salt &&cp conf/{master,minion} /etc/salt/
#test -f /etc/salt/minion &&
#cp pkg/rpm/{salt-minion,salt-master,salt-syndic} /etc/init.d/ && chmod +x /etc/init.d/salt-*
#test -f /etc/init.d/salt-minion && sed -r 's|MINION_ARGS=.*|MINION_ARGS="-c /etc/salt/minion"|' /etc/init.d/salt-minion
echo "#######################################
Config:
/etc/salt/
Start salt-minion:
/usr/bin/python /usr/bin/salt-minion -d
Start salt-master:
/usr/bin/python /usr/bin/salt-master -d"

#EXIT AND CLEAR TEMP DIR
exit_and_clear

}

main
