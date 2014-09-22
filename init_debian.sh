#!/bin/bash

yum_server='yum.lefu.local'
ntp_server='ntp.lefu.local'

#set DNS
echo 'nameserver 192.168.16.22' > /etc/resolv.conf

aptitude='aptitude -o Aptitude::Cmdline::ignore-trust-violations=true'

#install package
package='chkconfig vim rsync lftp mawk htop iftop xinetd nmap tcpdump lsof sysstat ntpdate sudo curl parted dnsutils'
echo -n "Install ${package} ... "
eval $aptitude install -y ${package} >/dev/null 2>&1 || install_package='fail' && echo 'done.'
if [ "${install_package}" = "fail" ];then
        echo "Install ${package} fail! Please check aptitude!" 1>&2
        exit 1
fi

#set vim for python
#grep -E '^#SET VIM' /etc/vimrc >/dev/null 2>&1 || echo "#SET VIM
#set ts=4" >> /etc/vimrc

#grep -E '^#SET VIM' /etc/vimrc >/dev/null 2>&1 || echo "#SET VIM
#syntax on" >> /etc/vimrc

test -f /etc/rc.local &&\
sed -i 's/exit 0//g' /etc/rc.local

test -d /etc/profile.d/ && \
cat << EOF > /etc/profile.d/vim_alias.sh
alias vi='vim -c "syntax on"'
EOF

#echo 'syntax on' > /root/.vimrc

#set ntp
echo -n "Set ntp ... "
eval $aptitude -y install ntpdate >/dev/null 2>&1 || install_ntp='fail'
if [ "${install_ntp}" = "fail" ];then
        echo "Install ntpdate fail! Please check aptitude!" 1>&2
        exit 1
else
        grep 'ntpdate' /etc/crontab >/dev/null 2>&1 || ntp_set='no'
        if [ "${ntp_set}" = "no" ];then
#                /usr/sbin/ntpdate ${ntp_server} >/dev/null 2>&1
                echo "*/15 * * * * root ntpdate ${ntp_server} > /dev/null 2>&1" >> /etc/crontab
                echo 'done.'
        fi
fi

#global
echo -n "set global.sh to /etc/profile.d/ ... "
if [ -d "/etc/profile.d/" ];then
        cd /etc/profile.d
        if [ ! -e global.sh ];then
                wget -q http://${yum_server}/shell/global.sh || install_env='fail'
                if [ "${install_env}" = "fail" ];then
                        echo "http://${yum_server}/shell/global.sh not exist!" 1>&2
                        exit 1
                fi
        fi
else
        echo "/etc/profile.d/ not exist!" 1>&2
        exit 1
fi
echo 'done.'

#set ulimit
grep -E '^ulimit.*' /etc/rc.local >/dev/null 2>&1 || echo "ulimit -Sn 4096
ulimit -Hn 10240" >> /etc/rc.local
limit_conf='/etc/security/limits.conf'
grep -E '^#-=SET Ulimit=-' ${limit_conf} >/dev/null 2>&1 ||set_limit="no"
if [ "${set_limit}" = 'no' ];then
test -f ${limit_conf} && echo '
#-=SET Ulimit=-
* soft nofile 4096
* hard nofile 10240
' >> ${limit_conf}
fi

if [ -f /etc/pam.d/su ];then
        sed -r -i 's|^.*pam_limits.so.*$|session    required   pam_limits.so|g' /etc/pam.d/su
fi

#add sysinfo
grep 'cron_sysinfo.sh' /etc/crontab >/dev/null 2>&1 || cron_sysinfo_set='no'
if [ "${cron_sysinfo_set}" = "no" ];then
	sysinfo_shell='/usr/sbin/cron_sysinfo.sh'
	wget -q http://${yum_server}/shell/cron_sysinfo.sh -O ${sysinfo_shell} ||\
	echo "Download cron_sysinfo.sh fail!" &&\
	echo "* * * * * root ${sysinfo_shell} > /dev/null 2>&1" >> /etc/crontab
	test -f ${sysinfo_shell} && chmod +x ${sysinfo_shell}
fi

#tunoff services
chkconfig --list|awk '/:on/{print $1}'|grep -E 'mpt-statusd|cups|avahi-daemon|nfs-common|portmap|exim4|rpcbind'|\
while read line
do
        chkconfig "${line}" off
        service "${line}" stop >/dev/null 2>&1
        echo "service ${line} stop"
done

#set sysctl
sysctl_cf='/etc/sysctl.conf'
if [ -f "${sysctl_cf}" ];then
        grep -E '^#SET sysctl.conf _END_' >/dev/null ${sysctl_cf} || sysctl_init='fail'
        if [ "${sysctl_init}" = 'fail' ]; then
                /sbin/sysctl -a > /etc/sysctl.conf.${mydate}
                echo '#init _BEGIN_
#net.ipv4.tcp_fin_timeout = 30
#net.ipv4.tcp_tw_reuse = 1
#net.ipv4.tcp_tw_recycle = 1
#net.ipv4.tcp_syncookies = 1
#net.ipv4.tcp_keepalive_time = 300
#net.ipv4.ip_local_port_range = 4000    65000
#net.ipv4.tcp_max_tw_buckets = 36000
#net.ipv4.route.gc_timeout = 100
#net.ipv4.tcp_syn_retries = 2
#net.ipv4.tcp_synack_retries = 2
#net.core.rmem_max = 16777216
#net.core.wmem_max = 16777216
#net.ipv4.tcp_rmem = 4096 87380 16777216
#net.ipv4.tcp_wmem = 4096 65536 16777216
#net.core.netdev_max_backlog = 30000
#net.ipv4.tcp_no_metrics_save = 1
#net.core.somaxconn = 262144
#net.ipv4.tcp_max_orphans = 262144
#net.ipv4.tcp_max_syn_backlog = 262144
#SET sysctl.conf _END_' >> ${sysctl_cf}
                /sbin/sysctl -p > ~/set_sysctl.log 2>&1
                echo "sysctl set OK!!"
        fi
fi

#set sshd
sshd_config='/etc/ssh/sshd_config'
test -e ${sshd_config} && sshd_service='true'
if [ "${sshd_service}" = 'true' ];then
        echo "set service sshd.modify ${sshd_config}"
        grep 'UseDNS' ${sshd_config} || echo "UseDNS no" >> ${sshd_config} && \
        sed -i -r 's/^UseDNS.*/UseDNS no/g' ${sshd_config}
        /etc/init.d/ssh restart
fi

echo "init service ok."
