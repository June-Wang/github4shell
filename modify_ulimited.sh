/bin/bash
#set ulimit
grep -E '^ulimit.*' /etc/rc.local >/dev/null 2>&1 || echo "ulimit -Sn 4096
ulimit -Hn 65536" >> /etc/rc.local
limit_conf='/etc/security/limits.conf'
grep -E '^#-=SET Ulimit=-' ${limit_conf} >/dev/null 2>&1 ||set_limit="no"
if [ "${set_limit}" = 'no' ];then
test -f ${limit_conf} && echo '
#-=SET Ulimit=-
* soft nofile 4096
* hard nofile 65536
' >> ${limit_conf}
fi
if [ -f /etc/pam.d/su ];then
        sed -r -i 's|^.*pam_limits.so.*$|session    required   pam_limits.so|g' /etc/pam.d/su
fi
