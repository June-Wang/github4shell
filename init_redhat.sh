#!/bin/bash

#dns server
dns_server='10.211.16.250'

#yum server
yum_server='yum.server.local'

#ntp server
ntp_server='ntp.server.local'

mark_file="/etc/init.info"

if [ -f "${mark_file}" ];then
        echo '系统已经进行过初始化'
        exit 1
fi

#set time
mydate=`date -d now +"%Y%m%d%H%M%S"`

#add to dns
#test -f /etc/resolv.conf && echo "nameserver ${dns_server}" > /etc/resolv.conf

echo -en '进行yum安装'
echo -en '\t->\t'
yum='yum --skip-broken --nogpgcheck'
$yum install -y net-tools wget rsync lftp vim ntpdate chkconfig htop xinetd epel-release >/dev/null 2>&1 && \
echo 'ok' || \
eval "echo yum安装失败!;exit 1"

echo -en '设置ntp时钟同步'
echo -en '\t->\t'
grep 'ntpdate' /etc/crontab >/dev/null 2>&1 || ntp_set='no'
if [ "${ntp_set}" = "no" ];then
        echo "*/15 * * * * root ntpdate ${ntp_server} > /dev/null 2>&1" >> /etc/crontab
        service crond restart
fi
echo 'ok'

echo -en '设置系统文件句柄打开数'
echo -en '\t->\t'
#set ulimited
test -f /etc/security/limits.d/100-app.conf ||\
echo '* soft nproc 10240
* hard nproc 10240
* soft nofile 60000
* hard nofile 60000' > /etc/security/limits.d/100-app.conf
echo 'ok'

echo -en '设置sysctl参数'
echo -en '\t->\t'
#set sysctl
sysctl_cf='/etc/sysctl.conf'
if [ -f "${sysctl_cf}" ];then
        grep -E '^#SET sysctl.conf _END_' >/dev/null ${sysctl_cf} || sysctl_init='fail'
        if [ "${sysctl_init}" = 'fail' ]; then 
                /sbin/sysctl -a > /etc/sysctl.conf.${mydate}
                echo '#init _BEGIN_
net.ipv4.tcp_timestamps = 0
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
net.ipv4.tcp_timestamps = 0
#SET sysctl.conf _END_' >> ${sysctl_cf}
                /sbin/sysctl -a > ~/set_sysctl.log 2>&1
        fi
fi
echo 'ok'

#echo -en '禁用ipv6'
#echo -en '\t->\t'
#disable ipv6
#keys=('alias net-pf-10 off' 'alias ipv6 off' 'options ipv6 disable=1')
#conf='/etc/modprobe.conf'
#if [ -f "${conf}" ];then
#        for key in "${keys[@]}"
#        do
#                grep "${key}" ${conf} >/dev/null 2>&1 || echo "${key}" >> ${conf}
#        done
#fi

#/sbin/chkconfig --list|grep 'ip6tables' >/dev/null 2>&1 && /sbin/chkconfig ip6tables off
#echo 'ok'

echo -en '禁用selinux'
echo -en '\t->\t'
#disable selinux
if [ -f "/etc/selinux/config" ];then
        cp /etc/selinux/config /etc/selinux/config.${mydate}
        sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config
        setenforce 0
fi
echo "ok" 1>&2

echo -en '设置vim别名'
echo -en '\t->\t'
#vim
sed -i "8 s/^/alias vi='vim'/" /root/.bashrc
#echo 'syntax on' > /root/.vimrc
echo "alias vi='vim'"  >> /etc/profile.d/vim_alias.sh
grep -E '^set ts=4' /etc/vimrc >/dev/null 2>&1 ||\
echo "set nocompatible
set ts=4
set backspace=indent,eol,start
syntax on" >> /etc/vimrc
echo 'ok'

echo -en '设置全局profile'
echo -en '\t->\t'
#global
if [ -d "/etc/profile.d/" ];then
        #cd /etc/profile.d
        wget -q http://${yum_server}/shell/global.sh -O /etc/profile.d/global.sh || install_env='fail'
        if [ "${install_env}" = "fail" ];then
                echo "http://${yum_server}/shell/global.sh not exist!" 1>&2
                exit 1
        else 
                echo 'ok'
        fi
else
        echo "/etc/profile.d/ not exist!" 1>&2
        exit 1
fi

echo -en '初始化sshd服务'
echo -en '\t->\t'
#init_ssh
ssh_cf="/etc/ssh/sshd_config"
if [ -f "${ssh_cf}" ];then
        sed -i "s/#UseDNS yes/UseDNS no/;s/^GSSAPIAuthentication.*$/GSSAPIAuthentication no/" $ssh_cf
        grep 'SSH vulnerabilities' ${ssh_cf} >/dev/null 2>&1 || echo '#SSH vulnerabilities
Ciphers aes128-ctr,aes192-ctr,aes256-ctr
MACs hmac-sha1,hmac-ripemd160' >> ${ssh_cf}
        service sshd restart
        #echo 'ok'
else
        echo "${ssh_cf} not find!"
        exit 1
fi

echo -en '关闭系统服务'
echo -en '\t->\t'
#turn off services
test -f /usr/bin/systemctl && mark='systemd'
if [ ${mark} == 'systemd' ];then
        cmd='systemctl list-unit-files|grep enabled'
else
        cmd='chkconfig --list|grep :on'
fi

eval "${cmd}"|awk '{print $1}'|\
grep -E 'rhnsd|rhsmcertd|certmonger|rhsmcertd|NetworkManager|rpcbind|portreserve|autofs|cpuspeed|postfix|ip6tables|mdmonitor|pcscd|iptables|bluetooth|nfslock|portmap|ntpd|cups|avahi-daemon|yum-updatesd|sendmail|firewalld'|\
sed 's/\.service//'|\
while read line
do
        chkconfig "${line}" off
        service "${line}" stop >/dev/null 2>&1
        echo "service ${line} stop"
done
echo "ok"

echo -en '关闭cron任务'
echo -en '\t->\t'
#rm cron job
for cron_file in /etc/cron.daily/makewhatis.cron /etc/cron.weekly/makewhatis.cron /etc/cron.daily/mlocate.cron
do
        test -e ${cron_file} && chmod -x ${cron_file}
done
echo 'ok'

echo -en '设置记录系统运行状态cron'
echo -en '\t->\t'
#add sysinfo
grep 'cron_sysinfo.sh' /etc/crontab >/dev/null 2>&1 || cron_sysinfo_set='no'
if [ "${cron_sysinfo_set}" = "no" ];then
        sysinfo_shell='/usr/sbin/cron_sysinfo.sh'
        wget -q http://${yum_server}/shell/cron_sysinfo.sh -O ${sysinfo_shell} ||\
        echo "Download cron_sysinfo.sh fail!" &&\
        echo "* * * * * root ${sysinfo_shell} > /dev/null 2>&1" >> /etc/crontab
        test -f ${sysinfo_shell} && chmod +x ${sysinfo_shell}
fi
echo 'ok'

echo -en '禁用ctrl+alt+del'
echo -en '\t->\t'
#close ctrl+alt+del
test -e /etc/inittab &&\
sed -i "s/ca::ctrlaltdel:\/sbin\/shutdown -t3 -r now/#ca::ctrlaltdel:\/sbin\/shutdown -t3 -r now/" /etc/inittab
echo 'ok'

echo "init ${system} ok" > ${mark_file} && exit 0
