#!/bin/bash

yum_server='10.211.16.250'
yum_package='xinetd nrpe nagios-plugins'

ls /usr/bin/yum >/dev/null 2>&1 ||\
eval "echo 未安装yum!;exit 1"

yum --skip-broken --nogpgcheck install -y ${yum_package} ||\
eval "echo yum安装失败!;exit 1"

test -d /etc/xinetd.d/ &&
echo 'service nrpe
{
        flags           = REUSE
        socket_type     = stream
        port            = 5666
        wait            = no
        user            = nagios
        group           = nagios
        server          = /usr/sbin/nrpe
        server_args     = -c /etc/nagios/nrpe.cfg --inetd
        log_on_failure  += USERID
        disable         = no
        only_from       = 127.0.0.1
}' > /etc/xinetd.d/nrpe

if [ -f /etc/services ];then
        grep -E '^nrpe' /etc/services >/dev/null 2>&1 || echo "nrpe 5666/tcp #NRPE" >> /etc/services
        service xinetd restart
fi

chkconfig nrpe off
chkconfig xinetd on

find /usr/lib*/ -type f -name 'check_nrpe'|xargs -r -i echo {} -H 127.0.0.1|/bin/bash
