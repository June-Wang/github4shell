#!/bin/bash

oracle_pkg='oracle11.2.0.4.161018.tar.gz'
log='/tmp/install_oracle.log'

echo -en 'yum安装oracle必要的依赖包'
echo -en '\t->\t'
yum --skip-broken --nogpgcheck install -y \
binutils \
compat-libstdc++-33 \
elfutils-libelf  \
elfutils-libelf-devel \
gcc  \
gcc-c++ \
glibc  \
glibc-common \
glibc-devel \
glibc-headers \
libaio \
libaio-devel \
libgcc \
libstdc++  \
libstdc++-devel \
libXp \
make  \
openmotif  \
sysstat  \
unixODBC \
unixODBC-devel >${log} 2>&1 ||\
eval "echo yum安装失败;exit 1" && \
echo 'ok'

echo -en '创建oracle用户及用户组'
echo -en '\t->\t'
groupadd -g 5000 oinstall >> ${log} 2>&1 || \
echo 'oinstall组已存在'
groupadd -g 5200 dba >> ${log} 2>&1 || \
echo 'dba组已存在'
groupadd -g 5300 oper >> ${log} 2>&1 || \
echo 'oper组已存在'
useradd -m -u 5001 -g oinstall -G dba -d /home/oracle -s /bin/bash -c "Oracle Software Owner" oracle >> ${log} 2>&1 || \
echo 'oracle用户已存在'
#passwd oracle
echo 'Oracle账户创建完毕'

#----创建目录
echo -en "下载${oracle_pkg}安装文件"
echo -en '\t->\t'
wget -q http://yum.server.local/tools/${oracle_pkg} -O /${oracle_pkg} ||\
eval "echo 下载${oracle_pkg}失败;exit 1" && echo 'ok'

echo -en "解压缩${oracle_pkg}"
echo -en '\t->\t'
test -f /${oracle_pkg} && cd / && tar xvf ${oracle_pkg} 
echo 'ok'

#mkdir -p /u01/app/oracle/product/11.2.0/dbhome_1
echo -en '目录授权'
echo -en '\t->\t'
test -d /u01 && chown -R oracle:oinstall /u01 || \
eval "echo 目录/u01不存在;exit 1"
chmod -R 775 /u01
echo 'ok'

#----------环境准备----------------------
echo -en '设置系统参数'
echo -en '\t->\t'
grep 'add for oracle dg' /etc/sysctl.conf >/dev/null 2>&1 && \
echo 'sysctl.conf已配置' || \
cat >> /etc/sysctl.conf <<EOF

###add for oracle dg###
net.ipv4.ip_forward = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
kernel.threads-max=65535
kernel.msgmni = 16384
kernel.msgmnb = 65535
kernel.msgmax = 65535
kernel.shmmax = 96636764160
kernel.shmall = 4294967296
kernel.shmmni = 4096
kernel.sem = 5010 641280 5010 128
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 32768
net.ipv4.tcp_no_metrics_save = 1
net.core.somaxconn = 32768
net.core.optmem_max = 10000000
net.ipv4.tcp_max_orphans = 32768
net.ipv4.tcp_max_syn_backlog = 32768
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes=10
net.ipv4.tcp_keepalive_intvl=2
net.ipv4.ip_local_port_range = 9000 65500
net.ipv4.route.gc_timeout = 100
net.ipv4.tcp_congestion_control=cubic
net.ipv4.conf.lo.arp_ignore = 1
net.ipv4.conf.lo.arp_announce = 2
net.ipv4.conf.all.arp_ignore = 1
net.ipv4.conf.all.arp_announce = 2
fs.aio-max-nr = 1048576
fs.file-max = 6815744
vm.swappiness = 0
EOF

echo 'sysctl.conf配置完毕'

grep 'for oracle limits' /etc/security/limits.conf &&\
echo 'limits.conf已配置' ||\
cat >> /etc/security/limits.conf <<EOF
#for oracle limits
oracle  soft nproc   16384
oracle  hard nproc   16384
oracle  soft nofile  10240
oracle  hard nofile  10240
EOF

echo 'limits.conf配置完毕'

grep 'for oracle login' /etc/pam.d/login >/dev/null 2>&1 &&\
echo 'login已配置' ||\
cat >> /etc/pam.d/login <<EOF
#for oracle login
session    required   /lib64/security/pam_limits.so
session    required     pam_limits.so
EOF

echo 'login配置完毕'

echo -en '删除临时文件'
echo -en '\t->\t'
test -f /${oracle_pkg} && rm -f /${oracle_pkg} ||\
eval "echo 删除临时文件失败;exit 1"

echo 'ok'
