#!/bin/bash

pkg='openssh-7.4p1.tar.gz'

wget http://yum.server.local/tools/${pkg} -O \
/tmp/${pkg} || \
eval "echo download ${pkg} fail!;exit 1"

rpm -e `rpm -qa openssh` --allmatches --nodeps

yum --skip-broken --nogpgcheck install -y openssl openssl-devel zlib-devel dropbear gcc glibc glibc-common make cmake gcc-c++ pam-devel ||\
eval 'echo yum install fail!;exit 1'

test -d /etc/dropbear ||\
mkdir -p /etc/dropbear

test -f /etc/dropbear/dropbear_dss_host_key ||\
/usr/bin/dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key

test -f /etc/dropbear/dropbear_rsa_host_key ||\
/usr/bin/dropbearkey -t rsa -s 4096 -f /etc/dropbear/dropbear_rsa_host_key

/usr/sbin/dropbear -p 2222

ls /tmp/${pkg} && \
cd /tmp/ ||\
eval 'echo /tmp/${pkg} not found!;exit 1' 

dir=`echo "${pkg}"|sed 's/.tar.gz//'`
tar -zxvf ${pkg} &&\
cd ${dir} ||\
eval 'echo unpack ${pkg} error!;exit 1'

./configure --prefix=/usr --sysconfdir=/etc/ssh  --with-pam --with-zlib --with-md5-passwords && \
make && make install

ls /etc/init.d/sshd >/dev/null 2>&1 && \
mv /etc/init.d/sshd /tmp/sshd.init.`date -d now +'%F'`.$$ 
cp contrib/redhat/sshd.init /etc/init.d/sshd

SSH_CONFIG="/etc/ssh/sshd_config"
test -f ${SSH_CONFIG} && sed -r -i 's/^(GSSAPI*)/#\1/g;s/^(UsePAM*)/#\1/g;s/^(UseDNS*)/#\1/g' ${SSH_CONFIG} ||\
eval "echo ${SSH_CONFIG} not found!;exit 1"

grep -E '^#-=SET SSHD=-' ${SSH_CONFIG} ||\
echo '#-=SET SSHD=-
UseDNS no   
UsePAM yes
PasswordAuthentication yes
PermitRootLogin yes 
PermitEmptyPasswords no
PasswordAuthentication yes' >> ${SSH_CONFIG}

SSH_CONFIG="/etc/ssh/ssh_config"
test -f ${SSH_CONFIG} && sed -i 's/GSSAPIAuthentication/#GSSAPIAuthentication/;s/^Host/#Host/' ${SSH_CONFIG} ||\
eval "echo ${SSH_CONFIG} not found!;exit 1"

chmod 600 /etc/ssh/ssh_*
rm -rf /tmp/openssh*

service sshd start && chkconfig sshd on
