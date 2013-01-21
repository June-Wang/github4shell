#!/bin/bash

#set yum server
yum_server='yum.suixingpay.com'

#set download
facter_url="http://${yum_server}/tools/facter-1.6.9.tar.gz"
puppet_url="http://${yum_server}/tools/puppet-2.7.14.tar.gz"

#set network
network="$(route -n|awk '/^0.0.0.0/{print $2}'|grep -oP '\d{1,3}(\.\d{1,3}){2}').0/24"

#alias yum local
alias yum='yum --disablerepo=\* --enablerepo=centos5-lan'

#install ruby ruby-rdoc
echo "Install ruby ruby-rdoc gcc glibc glibc-common. Please wait ....."
yum -y install ruby ruby-rdoc gcc glibc glibc-common > ~/install_ruby.log || yum_install='fail'
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

install_puppet_server () {
	file=`echo ${puppet_url}|awk -F'/' '{print $NF}'`
	dir=`echo ${file}|awk -F'.tar' '{print $1}'`
	tar xzf ${file} 
	cd ${dir}
	ruby install.rb > ~/install_${file}.log 2>&1
	test -e /etc/puppet/puppet.conf || cp ./conf/redhat/puppet.conf /etc/puppet/
	test -e /etc/puppet/fileserver.conf || cp ./conf/redhat/fileserver.conf /etc/puppet/
	cp ./conf/redhat/server.init /etc/init.d/puppetmaster
	cd ..
	chmod +x /etc/init.d/puppetmaster
	chkconfig puppetmaster on
	mkdir -p /etc/puppet/manifests/{classes,files,nodes}
	mkdir -p /etc/puppet/modules
	test -e /etc/puppet/manifests/site.pp || echo '
import "nodes/*.pp"
import "classes/*.pp"
' > /etc/puppet/manifests/site.pp
	test -e /etc/puppet/manifests/classes/test_class.pp || echo '
class test_class {
file { "/tmp/testfiles":
ensure => present,
mode => 644,
owner => root,
group => root
}
}	
'> /etc/puppet/manifests/classes/test_class.pp
	test -e /etc/puppet/manifests/nodes/client.pp || echo '
node client {
	include test_class
	}
' > /etc/puppet/manifests/nodes/client.pp
	test -e /etc/puppet/fileserver.conf || echo "
[files]
path /etc/puppet/manifests/files
allow ${network}
" > /etc/puppet/fileserver.conf
	mkdir -p /etc/puppet/manifests/files
	test -e /etc/puppet/puppet.conf || echo '
[puppetmaster]
autosign=true
autosign = /etc/puppet/autosign.conf
' > /etc/puppet/puppet.conf
test -e /etc/puppet/autosign.conf || echo '*' > /etc/puppet/autosign.conf
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
install_puppet_server

#add puppet server to /etc/hosts
host_cf='/etc/hosts'

#del tmp file
[ -d ~/"${puppet_install_dir}" ] && rm -rf ~/"${puppet_install_dir}"

[ -f "/etc/resolv.conf" ] && sed -i '/^search.*$/d' /etc/resolv.conf

#start puppet-server
cd ~/ && /usr/sbin/puppetmasterd --mkusers
#/etc/init.d/puppetmaster start
cd ~/
echo "Install puppet server complete!Start puppet server please type: /etc/init.d/puppetmaster start" && exit 0
#echo "Install puppet server Complete!" && exit 0
