#!/bin/bash

#set yum server
yum_server='yum.suixingpay.com'

#set download
facter_url="http://${yum_server}/tools/facter-1.6.9.tar.gz"
puppet_url="http://${yum_server}/tools/puppet-2.7.14.tar.gz"

#set puppet server
puppet_server_name='puppet-server'
pupet_server_ip='192.168.29.241'

#alias yum local
alias yum='yum --disablerepo=\* --enablerepo=centos5-lan'

#install ruby ruby-rdoc
echo "Install ruby ruby-rdoc gcc glibc glibc-common please wait ......"
yum -y install ruby ruby-rdoc gcc glibc glibc-common > install_ruby.log || yum_install='fail'
if [ "${yum_install}" = "fail" ];then
        echo "yum not available!" 1>&2
        exit 1
fi

#mkdir
puppet_install_dir="puppet_install_$$"
mkdir -p ~/${puppet_install_dir} && cd ~/${puppet_install_dir} || mkdir_puppet_dir='fail'

if [ "${mkdir_puppet_dir}" = "fail"  ];then
        echo "mkdir ${puppet_install_dir} fail!" 1>&2
        exit 1
fi

install_facter () {
	file=`echo ${facter_url}|awk -F'/' '{print $NF}'`
	dir=`echo ${file}|awk -F'.tar' '{print $1}'`
	tar xzf ${file}
	cd ${dir}
	ruby install.rb > ~/install_${file}.log 2>&1
	cd ..
}

puppet_cf='/etc/puppet/puppet.conf'

install_puppet_client () {
	file=`echo ${puppet_url}|awk -F'/' '{print $NF}'`
	dir=`echo ${file}|awk -F'.tar' '{print $1}'`
	tar xzf ${file} 
	cd ${dir}
	ruby install.rb > ~/install_${file}.log 2>&1
	cp ./conf/namespaceauth.conf /etc/puppet/ 
	cp ./conf/redhat/puppet.conf /etc/puppet/
	cp ./conf/redhat/client.init /etc/init.d/puppet
	cd ..
	chmod +x /etc/init.d/puppet
	chkconfig puppet on
	grep -E '^#SET AGENT _END_' >/dev/null 1>&2 ${puppet_cf} || set_puppet='fail'
	if [ "${set_puppet}" = "fail" ];then
	echo "
#SET AGENT _BEGIN_
runinterval = 600 #600秒
server=${puppet_server_name}
listen = true
[agent]
report = true
#SET AGENT _END_
" >> ${puppet_cf}
	fi
	sed -i -r 's/allow.*$/allow \*/g' /etc/puppet/namespaceauth.conf
}

#check facter puppet-client
urls=("${facter_url}" "${puppet_url}")
for url in "${urls[@]}"
do
	file=`echo ${url}|awk -F'/' '{print $NF}'`
	if [ ! -f "${file}" ]; then
		echo "download ${url}"
	        wget -q "${url}" || download='fail'
	        if [ "${download}" = "fail" ];then
        		echo "download ${url} fail!" 1>&2
                	exit 1
	        fi
	fi
done

install_facter
install_puppet_client 

#add puppet server to /etc/hosts
host_cf='/etc/hosts'
grep -E '^#SET PUPPET SERVER _END_' ${host_cf} >/dev/null 2>&1 || set_puppet_server='fail'

if [ "${set_puppet_server}" = 'fail' ];then
	echo -en "#SET PUPPET SERVER _START_\n${pupet_server_ip}\t${puppet_server_name}\n#SET PUPPET SERVER _END_\n" >> ${host_cf}
fi

#del tmp file
[ -d ~/"${puppet_install_dir}" ] && rm -rf ~/"${puppet_install_dir}"

#del search
[ -f "/etc/resolv.conf" ] && sed -i '/^search.*$/d' /etc/resolv.conf

#start puppet-client
echo "start puppet-client"
#/usr/sbin/puppetmasterd --mkusers
cd ~/ && /etc/init.d/puppet start
echo "Install puppet client complete!" && exit 0
