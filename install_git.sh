#!/bin/bash

#set yum server
yum_server='yum.suixingpay.com'

#set download
git_url="http://${yum_server}/tools/git-1.7.11-rc1.tar.gz"

#alias yum local
alias yum='yum --disablerepo=\* --enablerepo=centos5-lan'

#install lib
echo "Install curl curl-devel zlib-devel openssl-devel perl cpio expat-devel gettext-devel please wait ......"
yum -y install curl curl-devel zlib-devel openssl-devel perl cpio expat-devel gettext-devel > ~/install_git.log 2>&1 || yum_install='fail'
if [ "${yum_install}" = "fail" ];then
        echo "yum not available!" 1>&2
        exit 1
fi

#mkdir
tmp_dir="tmp_$$"
mkdir -p ~/${tmp_dir} && cd ~/${tmp_dir} || mkdir_tmp_dir='fail'

if [ "${mkdir_tmp_dir}" = "fail"  ];then
        echo "mkdir ${tmp_dir} fail!" 1>&2
        exit 1
fi

install_git () {
	file=`echo ${git_url}|awk -F'/' '{print $NF}'`
        dir=`echo ${file}|awk -F'.tar' '{print $1}'`
	tar xzf ${file}
	cd ${dir}
	echo -n "Compile ${file} please wait ...... "
	cmds=('make prefix=/usr/local all' 'make prefix=/usr/local install')
        for cmd in "${cmds[@]}"
        do
                ${cmd} >> ~/install_${file}.log 2>&1
        done
	echo "done."
	cd ..
}

#check facter puppet-client
urls=("${git_url}")
for url in "${urls[@]}"
do
        file=`echo ${url}|awk -F'/' '{print $NF}'`
        if [ ! -f "${file}" ]; then
                echo -n "download ${url} ......"
                wget -q "${url}" || download='fail'
                if [ "${download}" = "fail" ];then
                        echo "download ${url} fail!" 1>&2
                        exit 1
                fi
		echo "done."
        fi
done

install_git

#del tmp file
[ -d ~/"${tmp_dir}" ] && rm -rf ~/"${tmp_dir}"

git=`which git`

${git} --version && echo "Install git complete!" || echo "Install git fail!" 1>&2
