#!/bin/bash

check_system (){
ls /usr/bin/yum >/dev/null 2>&1 && SYSTEM='redhat'
ls /usr/bin/apt-get >/dev/null 2>&1 && SYSTEM='debian'
}

set_install_cmd () {
case "${SYSTEM}" in
        redhat)
                INSTALL_CMD='yum --skip-broken --nogpgcheck'
                CONFIG_CMD='chkconfig'
                MODIFY_SYSCONFIG='true'
        ;;
        debian)
                INSTALL_CMD='aptitude'
                CONFIG_CMD='chkconfig'
                eval "${INSTALL_CMD} install -y ${CONFIG_CMD}" >/dev/null 2>&1 || eval "echo ${install_cmd} fail! 1>&2;exit 1"
        ;;
        *)
                echo "This script not support ${SYSTEM_INFO}" 1>&2
                exit 1
        ;;
esac
}

main () {
#CHECK SYSTEM AND CREATE TEMP DIR
check_system
#create_tmp_dir
set_install_cmd

${INSTALL_CMD} install -y tripwire

test -d /etc/tripwire/ &&\
find /etc/tripwire/ -type f |grep -v '.txt'|\
xargs -r -i rm -f "{}"

date_now=`date -d now +"%F"`
pol_file='/etc/tripwire/twpol.txt'
test -f ${pol_file} && cp ${pol_file} ${pol_file}.${date_now}.$$
cat << "EOF" > ${pol_file}
@@section GLOBAL
TWBIN = /usr/sbin;
TWETC = /etc/tripwire;
TWVAR = /var/lib/tripwire;
HOSTNAME = localhost;

@@section FS
SEC_CRIT      = $(IgnoreNone)-SHa ; # Critical files that cannot change
SEC_BIN       = $(ReadOnly) ;        # Binaries that should not change
SEC_CONFIG    = $(Dynamic) ;         # Config files that are changed
                        # infrequently but accessed
                        # often
SEC_LOG       = $(Growing) ;         # Files that grow, but that
                                     # should never change ownership
SEC_INVARIANT = +tpug ;              # Directories that should never
                        # change permission or ownership
SIG_LOW       = 33 ;                 # Non-critical files that are of
                                     # minimal security impact
SIG_MED       = 66 ;                 # Non-critical files that are of
                                     # significant security impact
SIG_HI        = 100 ;                # Critical files that are
                                     # significant points of
                                     # vulnerability
(
  rulename = "Tripwire Binaries",
  severity = $(SIG_HI)
)
{
        $(TWBIN)/siggen                 -> $(SEC_BIN) ;
        $(TWBIN)/tripwire               -> $(SEC_BIN) ;
        $(TWBIN)/twadmin                -> $(SEC_BIN) ;
        $(TWBIN)/twprint                -> $(SEC_BIN) ;
}
(
  rulename = "Tripwire Data Files",
  severity = $(SIG_HI)
)
{
        $(TWVAR)/$(HOSTNAME).twd        -> $(SEC_CONFIG) -i ;
        $(TWETC)/tw.pol                 -> $(SEC_BIN) -i ;
        $(TWETC)/tw.cfg                 -> $(SEC_BIN) -i ;
        $(TWETC)/$(HOSTNAME)-local.key  -> $(SEC_BIN) ;
        $(TWETC)/site.key               -> $(SEC_BIN) ;
        #don't scan the individual reports
        $(TWVAR)/report                 -> $(SEC_CONFIG) (recurse=0) ;
}
(
  rulename = "Critical system boot files",
  severity = $(SIG_HI)
)
{
        /boot                   -> $(SEC_CRIT) ;
        /lib/modules            -> $(SEC_CRIT) ;
}
(
  rulename = "Boot Scripts",
  severity = $(SIG_HI)
)
{
        /etc/init.d             -> $(SEC_BIN) ;
#        /etc/rc.boot            -> $(SEC_BIN) ;
#        /etc/rcS.d              -> $(SEC_BIN) ;
        /etc/rc0.d              -> $(SEC_BIN) ;
        /etc/rc1.d              -> $(SEC_BIN) ;
        /etc/rc2.d              -> $(SEC_BIN) ;
        /etc/rc3.d              -> $(SEC_BIN) ;
        /etc/rc4.d              -> $(SEC_BIN) ;
        /etc/rc5.d              -> $(SEC_BIN) ;
        /etc/rc6.d              -> $(SEC_BIN) ;
}
(
  rulename = "Root file-system executables",
  severity = $(SIG_HI)
)
{
        /bin                    -> $(SEC_BIN) ;
        /sbin                   -> $(SEC_BIN) ;
}
(
  rulename = "Root file-system libraries",
  severity = $(SIG_HI)
)
{
        /lib                    -> $(SEC_BIN) ;
}
(
  rulename = "Security Control",
  severity = $(SIG_MED)
)
{
        /etc/passwd             -> $(SEC_CONFIG) ;
        /etc/shadow             -> $(SEC_CONFIG) ;
}
(
  rulename = "System boot changes",
  severity = $(SIG_HI)
)
{
}
(
  rulename = "Root config files",
  severity = 100
)
{
        /root/.bashrc                   -> $(SEC_CONFIG) ;
        /root/.bash_profile             -> $(SEC_CONFIG) ;
}
(
  rulename = "Devices & Kernel information",
  severity = $(SIG_HI),
)
{
}
(
  rulename = "Other configuration files",
  severity = $(SIG_MED)
)
{
        /etc            -> $(SEC_BIN) ;
}
(
  rulename = "Other binaries",
  severity = $(SIG_MED)
)
{
        /usr/local/sbin -> $(SEC_BIN) ;
        /usr/local/bin  -> $(SEC_BIN) ;
        /usr/sbin       -> $(SEC_BIN) ;
        /usr/bin        -> $(SEC_BIN) ;
}
(
  rulename = "Other libraries",
  severity = $(SIG_MED)
)
{
        /usr/local/lib  -> $(SEC_BIN) ;
        /usr/lib        -> $(SEC_BIN) ;
}
(
  rulename = "Invariant Directories",
  severity = $(SIG_MED)
)
{
}
EOF

if [ ${SYSTEM} = 'redhat' ];then
        /usr/sbin/tripwire-setup-keyfiles
else
        /usr/sbin/tripwire --update-policy --secure-mode low /etc/tripwire/twpol.txt
fi

/usr/sbin/tripwire --init && /usr/sbin/tripwire --check

}

main
