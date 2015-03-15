#!/bin/bash

nagios_server='192.168.16.21'
yum_server='yum.server.local'

apt_cmd='aptitude install -y'
echo -en "${apt_cmd} xinetd ..."
eval "${apt_cmd} xinetd" >/dev/null 2>&1 || eval "echo ${apt_cmd} xinetd error!;exit 1" &&\
echo "done."

#package='check-mk-agent_1.2.4p5-2_all.deb'
package='check-mk-agent_1.2.5i6-2_all.deb'
echo  "Install ${package} ..."
eval "wget http://${yum_server}/tools/${package} -O /tmp/${package} >/dev/null" && dpkg -i /tmp/${package}

check_mk_conf='/etc/xinetd.d/check_mk'
test -f ${check_mk_conf} || eval "echo check_mk not been installed!;exit 1" &&\
sed -r -i "s/#only_from.*/only_from = 127.0.0.1 ${nagios_server}/" ${check_mk_conf} 

/etc/init.d/xinetd restart
