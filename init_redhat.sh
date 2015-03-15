#!/bin/bash

#dns server
dns_server='192.168.1.201'

#yum server
yum_server='yum.server.local'

#ntp server
ntp_server='ntp.server.local'

system_info=`head -n 1 /etc/issue`
case "${system_info}" in
        'CentOS release 5'*)
                system='centos5'
                yum_source_name='centos5-lan'
                ;;
        'Red Hat Enterprise Linux Server release 5'*)
                system='rhel5'
                yum_source_name='RHEL5-lan'
                ;;
        'Red Hat Enterprise Linux Server release 6'*)
                system='rhel6'
                yum_source_name='RHEL6-lan'
                ;;
        *)
                system='unknown'
                echo "This script not support ${system_info}" 1>&2
                exit 1
                ;;
esac

mark_file="/etc/init_${system}.info"

[ -f "${mark_file}" ] && exit 1

#set time
mydate=`date -d now +"%Y%m%d%H%M%S"`

#add to dns
test -f /etc/resolv.conf && echo "nameserver ${dns_server}" > /etc/resolv.conf

yum='yum --skip-broken --nogpgcheck'

$yum install -y wget rsync lftp vim >/dev/null 2>&1 || eval "echo YUM Failed!;exit 1"

#set ntp
$yum -y install ntp >/dev/null 2>&1 || install_ntp='fail'
if [ "${install_ntp}" = "fail" ];then
        echo "yum fail! ntp install fail!" 1>&2
        exit 1
else
        grep 'ntpdate' /etc/crontab >/dev/null 2>&1 || ntp_set='no'
        if [ "${ntp_set}" = "no" ];then
                echo "*/15 * * * * root ntpdate ${ntp_server} > /dev/null 2>&1" >> /etc/crontab
                service crond restart
        fi
fi

#set ulimit
grep -E '^ulimit.*' /etc/rc.local >/dev/null 2>&1 || echo "ulimit -SHn 4096" >> /etc/rc.local
limit_conf='/etc/security/limits.conf'
grep -E '^#-=SET Ulimit=-' ${limit_conf} >/dev/null 2>&1 ||set_limit="no"
if [ "${set_limit}" = 'no' ];then
test -f ${limit_conf} && echo '
#-=SET Ulimit=-
* soft nofile 4096
* hard nofile 65536
' >> ${limit_conf}
fi

#set locale
#true > /etc/sysconfig/i18n
#cat >>/etc/sysconfig/i18n<<EOF
#LANG="zh_CN.GB18030"
#SUPPORTED="zh_CN.GB18030:zh_CN:zh:en_US.UTF-8:en_US:en" 
#SYSFONT="latarcyrheb-sun16"
#EOF

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

#disable ipv6
keys=('alias net-pf-10 off' 'alias ipv6 off' 'options ipv6 disable=1')
conf='/etc/modprobe.conf'
if [ -f "${conf}" ];then
        for key in "${keys[@]}"
        do
                grep "${key}" ${conf} >/dev/null 2>&1 || echo "${key}" >> ${conf}
        done
fi

/sbin/chkconfig --list|grep 'ip6tables' >/dev/null 2>&1 && /sbin/chkconfig ip6tables off
echo "ipv6 is disabled!"

#disable selinux
if [ -f "/etc/selinux/config" ];then
        cp /etc/selinux/config /etc/selinux/config.${mydate}
        sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config
        echo "selinux is disabled,you must reboot!" 1>&2
fi

#vim
sed -i "8 s/^/alias vi='vim'/" /root/.bashrc
#echo 'syntax on' > /root/.vimrc
echo "alias vi='vim'"  >> /etc/profile.d/vim_alias.sh
grep -E '^set ts=4' /etc/vimrc >/dev/null 2>&1 ||\
echo "set nocompatible
set ts=4
set backspace=indent,eol,start
syntax on" >> /etc/vimrc

#global
echo "set global.sh to /etc/profile.d/"
if [ -d "/etc/profile.d/" ];then
        cd /etc/profile.d
        wget -q http://${yum_server}/shell/global.sh || install_env='fail'
        if [ "${install_env}" = "fail" ];then
                echo "http://${yum_server}/shell/global.sh not exist!" 1>&2
                exit 1
        fi
else
        echo "/etc/profile.d/ not exist!" 1>&2
        exit 1
fi

#init_ssh
ssh_cf="/etc/ssh/sshd_config"
if [ -f "${ssh_cf}" ];then
        sed -i "s/#UseDNS yes/UseDNS no/;s/^GSSAPIAuthentication.*$/GSSAPIAuthentication no/" $ssh_cf
        service sshd restart
echo "init sshd ok."
else
        echo "${ssh_cf} not find!"
        exit 1
fi

#tunoff services
chkconfig --list|awk '/:on/{print $1}'|\
grep -E 'rpcbind|portreserve|autofs|auditd|cpuspeed|postfix|ip6tables|mdmonitor|pcscd|iptables|bluetooth|nfslock|portmap|ntpd|cups|avahi-daemon|yum-updatesd|sendmail'|\
while read line
do
        chkconfig "${line}" off
        service "${line}" stop >/dev/null 2>&1
        echo "service ${line} stop"
done
echo "init service ok."

#rm cron job
for cron_file in /etc/cron.daily/makewhatis.cron /etc/cron.weekly/makewhatis.cron /etc/cron.daily/mlocate.cron
do
        test -e ${cron_file} && chmod -x ${cron_file}
done

#add sysinfo
grep 'cron_sysinfo.sh' /etc/crontab >/dev/null 2>&1 || cron_sysinfo_set='no'
if [ "${cron_sysinfo_set}" = "no" ];then
        sysinfo_shell='/usr/sbin/cron_sysinfo.sh'
        wget -q http://${yum_server}/shell/cron_sysinfo.sh -O ${sysinfo_shell} ||\
        echo "Download cron_sysinfo.sh fail!" &&\
        echo "* * * * * root ${sysinfo_shell} > /dev/null 2>&1" >> /etc/crontab
        test -f ${sysinfo_shell} && chmod +x ${sysinfo_shell}
fi

#close ctrl+alt+del
test -e /etc/inittab &&\
sed -i "s/ca::ctrlaltdel:\/sbin\/shutdown -t3 -r now/#ca::ctrlaltdel:\/sbin\/shutdown -t3 -r now/" /etc/inittab

echo "init ${system} ok" > ${mark_file} && exit 0
