#!/bin/bash

#set yum server
yum_server='yum.suixingpay.com'

#alias yum local
alias yum='yum --disablerepo=\* --enablerepo=centos5-lan'

#download url
unison_url="http://${yum_server}/tools/unison-2.40.63.tar.gz"
ocaml_url="http://${yum_server}/tools/ocaml-3.12.1.tar.gz"

#local install path
local_path='/usr/local/src'
install_dir="install_$$"

#install gcc openssl
install_lib () {
echo -n "install gcc openssl glib2 please wait ......"
yum -y install gcc gcc-c++ openssl openssl-devel glib2-devel > ${local_path}/yum_for_unison.log 2>&1 && echo 'done.' || yum_install='fail'
if [ "${yum_install}" = "fail" ];then
        echo "yum not available!" 1>&2
        exit 1
fi
}

#mkdir for install
make_dir () {
test -d "${local_path}" || mkdir -p "${local_path}" 
cd ${local_path}
mkdir -p ${install_dir} && cd ${install_dir} || mkdir_dir='fail'

if [ "${mkdir_dir}" = 'fail'  ];then
        echo "mkdir ${install_dir} fail!" 1>&2
        exit 1
fi
}

del_tmp () {
#del tmp file
test -d "${local_path}/${install_dir}" && rm -rf "${local_path}/${install_dir}"
}

check_urls () {
for url in "$@"
do
        file=`echo ${url}|awk -F'/' '{print $NF}'`
        if [ ! -f "${file}" ]; then
                echo -n "download ${url} ..."
                wget -q "${url}"  && echo 'done.' || download='fail'
                if [ "${download}" = "fail" ];then
                        echo "download ${url} fail!" 1>&2 && del_tmp
                        exit 1
                fi
        fi
done
}

install_pre () {
        install_url="$1"
        file=`echo ${install_url}|awk -F'/' '{print $NF}'`
        dir=`echo ${file}|awk -F'.tar' '{print $1}'`
        test -e "${file}" && tar xzf ${file} || tar_file='not_exist'
        cd ${dir} || file_dir='not_exist'
        if [ "${tar_file}" = 'not_exist' ];then
                echo "${file} not exist!" 1>&2 && del_tmp
                exit 1
        fi
        if [ "${file_dir}" = 'not_exist' ];then
                echo "plesse check ${file}!" 1>&2 && del_tmp
                exit 1
        fi
        echo -n "Compile ${dir} please wait ...... "
}

run_cmds () {
	cmd_log="${local_path}/install_${dir}.log"
        test -f "${cmd_log}" && cat /dev/null > "${local_path}/install_${dir}.log"
        for cmd in "$@"
        do
                ${cmd} >> "${cmd_log}" 2>&1 || compile='fail'
                if [ "${compile}" = 'fail' ]; then
                        echo "run ${cmd} error! please type: less ${cmd_log}" 1>&2 && del_tmp
                        exit 1
                fi
        done
        echo "done."
}

install_ocaml () {
        install_pre "${ocaml_url}"
        run_cmds './configure' 'make world opt' 'make install'
        cd ..
}

install_unison () {
        install_pre "${unison_url}"
        run_cmds 'make UISTYLE=text THREADS=true STATIC=true'
        cp unison /usr/local/bin
        cd ..
}

make_template () {
	mkdir -p /root/.unison
	echo "root = /root/test
root = ssh://root@192.168.56.151//root/test
#force =/sina/webdata
#ignore = Path as/*
#prefer = ssh://root@192.168.60.121//www/webdata
batch = true
#repeat = 1
#retry = 3
owner = true
group = true
perms = -1
fastcheck=true
rsync =false
#debug=verbose
sshargs = -C
xferbycopying = true
log = true
logfile = /root/.unison/test.log
" > /root/.unison/test.prf
}

main (){
install_lib
make_dir
check_urls "${unison_url}" "${ocaml_url}"
install_ocaml
install_unison
make_template
del_tmp
}

main
echo "Install unison complete!" && exit 0
