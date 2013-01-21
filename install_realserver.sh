#!/bin/bash

install_realserver () {
        sns_vip="$1"
        echo '#!/bin/bash  
SNS_VIP='${sns_vip}'  
. /etc/rc.d/init.d/functions  
case "$1" in  
start)  
       ifconfig lo:0 $SNS_VIP netmask 255.255.255.255 broadcast $SNS_VIP  
       /sbin/route add -host $SNS_VIP dev lo:0  
       echo "1" >/proc/sys/net/ipv4/conf/lo/arp_ignore  
       echo "2" >/proc/sys/net/ipv4/conf/lo/arp_announce  
       echo "1" >/proc/sys/net/ipv4/conf/all/arp_ignore  
       echo "2" >/proc/sys/net/ipv4/conf/all/arp_announce  
       sysctl -p >/dev/null 2>&1  
       echo "RealServer Start OK"   
       ;;  
stop)  
       ifconfig lo:0 down  
       route del $SNS_VIP >/dev/null 2>&1  
       echo "0" >/proc/sys/net/ipv4/conf/lo/arp_ignore  
       echo "0" >/proc/sys/net/ipv4/conf/lo/arp_announce  
       echo "0" >/proc/sys/net/ipv4/conf/all/arp_ignore  
       echo "0" >/proc/sys/net/ipv4/conf/all/arp_announce  
       echo "RealServer Stoped"  
       ;;  
*)  
       echo "Usage: $0 {start|stop}"  
       exit 1  
esac  
exit 0' >/etc/init.d/realserver
chmod +x /etc/init.d/realserver

grep -E '^#SET ipvsadm auto run _END_' /etc/rc.local >/dev/null 2>&1 || set_auto='fail'
if [ "${set_auto}" = 'fail' ];then
echo '#SET ipvsadm auto run _BEGIN_
/etc/init.d/realserver start
#SET ipvsadm auto run _END_' >>/etc/rc.local
fi

}

echo_bye () {
        program="$1"
        echo "Install ${program} complete! Please type : /etc/init.d/realserver start " && exit 0
}

usage () {
        echo "Usage: $0 [IP] (VIP addr)" 1>&2
        exit 1
}

main () {
my_project='realserver'
install_realserver ${VIP}
echo_bye "${my_project}"
}

para="$1"

VIP=`echo "${para}"|grep -oP '\d{1,3}(\.\d{1,3}){3}'`
[ -z "${VIP}" ] && usage
main
