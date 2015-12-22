#!/bin/bash

#SET ENV
YUM_SERVER='yum.server.local'
PACKAGE_URL="http://${YUM_SERVER}/tools"

#SET TEMP PATH
TEMP_PATH='/usr/local/src'

#SET TEMP DIR
INSTALL_DIR="install_$$"
INSTALL_PATH="${TEMP_PATH}/${INSTALL_DIR}"

#SET PACKAGE
YUM_PACKAGE='tripwire'
APT_PACKAGE='tripwire'

#SET EXIT STATUS AND COMMAND
trap "exit 1"           HUP INT PIPE QUIT TERM
trap "rm -rf ${INSTALL_PATH}"  EXIT

download_func () {
local func_shell='func4install.sh'
local func_url="http://${YUM_SERVER}/shell/${func_shell}"
local tmp_file="/tmp/${func_shell}"

wget -q ${func_url} -O ${tmp_file} && source ${tmp_file} ||\
eval "echo Can not access ${func_url}! 1>&2;exit 1"
rm -f ${tmp_file}
}

main () {
#DOWNLOAD FUNC FOR INSTALL
download_func

#CHECK SYSTEM AND CREATE TEMP DIR
check_system
#create_tmp_dir
set_install_cmd 'net'

create_tmp_dir
#download_and_check
#run_cmds './configure --prefix=/usr' 'make' 'make install'

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

if [ ${ISSUE} = 'redhat' ];then
	/usr/sbin/tripwire-setup-keyfiles
else
	/usr/sbin/tripwire --update-policy --secure-mode low /etc/tripwire/twpol.txt
fi

/usr/sbin/tripwire --init && /usr/sbin/tripwire --check

#EXIT AND CLEAR TEMP DIR
exit_and_clear

}

main
