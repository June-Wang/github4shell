#!/bin/bash

test -f  /usr/bin/yum &&\
yum install -y net-tools wget rsync lftp vim ntpdate chkconfig htop xinetd epel-release

#set ulimit
grep -E '^ulimit.*' /etc/rc.local >/dev/null 2>&1 || echo "ulimit -SHn 65536" >> /etc/rc.local
limit_conf='/etc/security/limits.conf'
grep -E '^#-=SET Ulimit=-' ${limit_conf} >/dev/null 2>&1 ||set_limit="no"
if [ "${set_limit}" = 'no' ];then
test -f ${limit_conf} && echo '
#-=SET Ulimit=-
* soft nofile 65536
* hard nofile 65536
' >> ${limit_conf}
fi

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
#SET sysctl.conf _END_
' >> ${sysctl_cf}

                /sbin/sysctl -p > ~/set_sysctl.log 2>&1
                echo "sysctl set OK!!"
        fi
fi

#disable selinux
if [ -f "/etc/selinux/config" ];then
        cp /etc/selinux/config /etc/selinux/config.${mydate}
        sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config
        echo "selinux is disabled,you must reboot!" 1>&2
fi

#vim
sed -i "8 s/^/alias vi='vim'/" /root/.bashrc
echo 'syntax on' > /root/.vimrc
echo "alias vi='vim'"  >> /etc/profile.d/vim_alias.sh
grep -E '^set ts=4' /etc/vimrc >/dev/null 2>&1 || echo "set ts=4" >> /etc/vimrc

#init_ssh
ssh_cf="/etc/ssh/sshd_config"
if [ -f "${ssh_cf}" ];then
        sed -i "s/#UseDNS yes/UseDNS no/" $ssh_cf
        service sshd restart
echo "init sshd ok."
else
        echo "${ssh_cf} not find!"
        exit 1
fi

systemctl disable postfix.service
systemctl disable NetworkManager

