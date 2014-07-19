#!/bin/bash

nrpe_conf='/usr/local/nagios/etc/nrpe.cfg'
nrpe_url='http://yum.suixingpay.local/shell'
test -f ${nrpe_conf} || exit 1
grep 'check_disk_root' ${nrpe_conf} ||\
echo 'command[check_disk_root]=/usr/local/nagios/libexec/check_disk -w 20% -c 10% -p /' >> ${nrpe_conf}

grep 'check_cpu_utilization' ${nrpe_conf}||\
echo 'command[check_cpu_utilization]=/usr/local/nagios/libexec/check_cpu_utilization.sh -w 300 -c 500' >> ${nrpe_conf}
wget "${nrpe_url}/check_cpu_utilization.sh" -O /usr/local/nagios/libexec/check_cpu_utilization.sh
chmod +x /usr/local/nagios/libexec/check_cpu_utilization.sh
/usr/local/nagios/libexec/check_cpu_utilization.sh -w 300 -c 500

grep 'check_tcp_stat' ${nrpe_conf}||\
echo 'command[check_tcp_stat]=/usr/local/nagios/libexec/check_tcp_stat.sh -w 300 -c 500 -l' >> ${nrpe_conf}
wget "${nrpe_url}/check_tcp_stat.sh" -O /usr/local/nagios/libexec/check_tcp_stat.sh &&\
chmod +x /usr/local/nagios/libexec/check_tcp_stat.sh && /usr/local/nagios/libexec/check_tcp_stat.sh -w 300 -c 500 -l

wget "${nrpe_url}/check_lsof.sh" -O /usr/local/nagios/libexec/check_lsof.sh
chmod +x /usr/local/nagios/libexec/check_lsof.sh

grep 'check_ntp_time' ${nrpe_conf}||\
echo 'command[check_ntp_time]=/usr/local/nagios/libexec/check_ntp_time -H ntp.suixingpay.local -w 0.5 -c 1' >> ${nrpe_conf}

grep 'check_bond0' ${nrpe_conf} ||\
echo 'command[check_bond0]=/usr/local/nagios/libexec/check_bond.sh -d bond0' >> ${nrpe_conf}
wget "${nrpe_url}/check_bond.sh" -O /usr/local/nagios/libexec/check_bond.sh
chmod +x /usr/local/nagios/libexec/check_bond.sh
#/usr/local/nagios/libexec/check_bond.sh -d bond0

grep 'check_NIC' ${nrpe_conf} ||\
echo 'command[check_NIC]=/usr/local/nagios/libexec/check_NIC.sh' >> ${nrpe_conf}
wget "${nrpe_url}/check_NIC.sh" -O /usr/local/nagios/libexec/check_NIC.sh
chmod +x /usr/local/nagios/libexec/check_NIC.sh

wget "${nrpe_url}/check_denyhosts.sh" -O /usr/local/nagios/libexec/check_denyhosts.sh
chmod +x /usr/local/nagios/libexec/check_denyhosts.sh
grep 'check_denyhosts' ${nrpe_conf}||\
echo 'command[check_denyhosts]=/usr/local/nagios/libexec/check_denyhosts.sh' >> ${nrpe_conf}

grep 'check_mem' ${nrpe_conf} ||\
echo 'command[check_mem]=/usr/local/nagios/libexec/check_mem.sh -w 75 -c 85' >> ${nrpe_conf}
wget "${nrpe_url}/check_mem.sh" -O /usr/local/nagios/libexec/check_mem.sh
chmod +x /usr/local/nagios/libexec/check_mem.sh

grep 'check_swap' ${nrpe_conf} ||\
echo 'command[check_swap]=/usr/local/nagios/libexec/check_swap -w 20% -c 10%' >> ${nrpe_conf}

grep 'check_net_traffic' ${nrpe_conf} ||\
echo 'command[check_net_traffic]=/usr/local/nagios/libexec/check_net_traffic.sh -d eth0 -w 50m -c 75m' >> ${nrpe_conf}
wget "${nrpe_url}/check_net_traffic.sh" -O /usr/local/nagios/libexec/check_net_traffic.sh
chmod +x /usr/local/nagios/libexec/check_net_traffic.sh
/usr/local/nagios/libexec/check_net_traffic.sh -d eth0 -w 50m -c 75m

#curl -s http://yum.suixingpay.com/shell/install_nagios-plugins.sh|sh
