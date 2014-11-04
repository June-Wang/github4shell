#!/bin/bash

#SET ENV
YUM_SERVER='yum.lefu.local'
PACKAGE_URL="http://${YUM_SERVER}/tools"

#SET TEMP PATH
TEMP_PATH='/usr/local/src'

#SET TEMP DIR
INSTALL_DIR="install_$$"
INSTALL_PATH="${TEMP_PATH}/${INSTALL_DIR}"

#SET PACKAGE
YUM_PACKAGE='gcc glibc glibc-common make cmake gcc-c++'
APT_PACKAGE='build-essential libtool python python-dev python-jinja2 python-yaml m2crypto'

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

post_init () {
ln -s /usr/local/bin/salt-* /usr/bin/

cat << "EOF" > /etc/init.d/salt-minion
#!/bin/sh
#
# Salt minion
###################################
# /usr/bin/salt-minion
#
# Written by Miquel van Smoorenburg <miquels@drinkel.ow.org>.
# Modified for Debian GNU/Linux by Ian Murdock <imurdock@gnu.ai.mit.edu>.
# Modified for exim by Tim Cutts <timc@chiark.greenend.org.uk>
# Modified for exim4 by Andreas Metzler <ametzler@downhill.at.eu.org>
#                   and Marc Haber <mh+debian-packages@zugschlus.de>

### BEGIN INIT INFO
# Provides:          salt-minion
# Required-Start:    $remote_fs $syslog $named $network $time
# Required-Stop:     $remote_fs $syslog $named $network
# Should-Start:      postgresql mysql clamav-daemon greylist spamassassin
# Should-Stop:       postgresql mysql clamav-daemon greylist spamassassin
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: salt minion control daemon 
# Description:       salt minion control daemon 
### END INIT INFO

# processname: /usr/bin/salt-minion
 
SERVICE=salt-minion
PROCESS="/usr/bin/$SERVICE"
PYTHON="/usr/bin/python"
CONFIG_ARGS="-c /etc/salt/"
 
# Sanity checks.
[ -x $PROCESS ] || exit 0
 
DEBIAN_VERSION=/etc/debian_version
SUSE_RELEASE=/etc/SuSE-release
# Source function library.
if [ -f $DEBIAN_VERSION ]; then
   break
elif [ -f $SUSE_RELEASE -a -r /etc/rc.status ]; then
    . /etc/rc.status
else
    . /etc/rc.d/init.d/functions
fi
 
RETVAL=0
 
start() {
    echo -n "Starting salt-minion daemon: "
    if [ -f $SUSE_RELEASE ]; then
        startproc -f -p /var/run/$SERVICE.pid $PROCESS -d -l quiet $CONFIG_ARGS
        rc_status -v
    elif [ -e $DEBIAN_VERSION ]; then
        if ps aux | grep "$PYTHON[ ]$PROCESS" 2>&1 > /dev/null; then
            echo -n "already started, lock file found"
            RETVAL=1
        elif $PYTHON $PROCESS -d -l quiet $CONFIG_ARGS; then
            echo -n "OK"
            RETVAL=0
        fi
    else
        daemon --check $SERVICE $PROCESS -d -l quiet $CONFIG_ARGS
    fi
    RETVAL=$?
    echo
    return $RETVAL
}
 
stop() {
    echo -n "Stopping salt-minion daemon: "
    if [ -f $SUSE_RELEASE ]; then
        killproc -TERM $PROCESS
        rc_status -v
    elif [ -f $DEBIAN_VERSION ]; then
        # Added this since Debian's start-stop-daemon doesn't support spawned processes
        if ps aux | grep "$PYTHON[ ]$PROCESS" 2>&1 > /dev/null; then
            ps aux | grep "$PYTHON[ ]$PROCESS" | awk '{ print $2 }' | xargs kill
            echo -n "OK"
            RETVAL=0
        else
            echo -n "Daemon is not started"
            RETVAL=1
        fi
    else
        killproc $PROCESS
    fi
    RETVAL=$?
    echo
}
 
restart() {
    stop
    sleep 1
    start
}
 
# See how we were called.
case "$1" in
    start|stop|restart)
        $1
        ;;
    status)
        if [ -f $SUSE_RELEASE ]; then
            echo -n "Checking for service salt-minion "
            checkproc $PROCESS
            rc_status -v
        elif [ -f $DEBIAN_VERSION ]; then
            if ps aux | grep "$PYTHON[ ]$PROCESS" 2>&1 > /dev/null; then
                RETVAL=0
                echo "salt-minion is running."
            else
                RETVAL=1
                echo "salt-minion is stopped."
            fi
        else
            status $PROCESS
            RETVAL=$?
        fi
        ;;
    condrestart)
        [ -f $LOCKFILE ] && restart || :
        ;;
    reload)
        echo "can't reload configuration, you have to restart it"
        RETVAL=$?
        ;;
    *)
        echo $"Usage: $0 {start|stop|status|restart|condrestart|reload}"
        exit 1
        ;;
esac
exit $RETVAL
EOF

chmod +x /etc/init.d/salt-minion

cat << "EOF" > /etc/init.d/salt-master
#!/bin/sh
#
# Salt Master
###################################

# /usr/bin/salt-master
#
# Written by Miquel van Smoorenburg <miquels@drinkel.ow.org>.
# Modified for Debian GNU/Linux by Ian Murdock <imurdock@gnu.ai.mit.edu>.
# Modified for exim by Tim Cutts <timc@chiark.greenend.org.uk>
# Modified for exim4 by Andreas Metzler <ametzler@downhill.at.eu.org>
#                   and Marc Haber <mh+debian-packages@zugschlus.de>

### BEGIN INIT INFO
# Provides:          salt-master
# Required-Start:    $remote_fs $syslog $named $network $time
# Required-Stop:     $remote_fs $syslog $named $network
# Should-Start:      postgresql mysql clamav-daemon greylist spamassassin
# Should-Stop:       postgresql mysql clamav-daemon greylist spamassassin
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: salt master control daemon 
# Description:       salt master control daemon 
### END INIT INFO

# processname: /usr/bin/salt-master
 
SERVICE=salt-master
PROCESS="/usr/bin/$SERVICE"
PYTHON="/usr/bin/python"
CONFIG_ARGS="-c /etc/salt/"
 
# Sanity checks.
[ -x $PROCESS ] || exit 0
 
DEBIAN_VERSION=/etc/debian_version
SUSE_RELEASE=/etc/SuSE-release
# Source function library.
if [ -f $DEBIAN_VERSION ]; then
   break
elif [ -f $SUSE_RELEASE -a -r /etc/rc.status ]; then
    . /etc/rc.status
else
    . /etc/rc.d/init.d/functions
fi
 
RETVAL=0
 
start() {
    echo -n "Starting salt-master daemon: "
    if [ -f $SUSE_RELEASE ]; then
        startproc -f -p /var/run/$SERVICE.pid $PROCESS -d -l quiet $CONFIG_ARGS
        rc_status -v
    elif [ -e $DEBIAN_VERSION ]; then
        if ps aux | grep "$PYTHON[ ]$PROCESS" 2>&1 > /dev/null; then
            echo -n "already started, lock file found"
            RETVAL=1
        elif $PYTHON $PROCESS -d -l quiet $CONFIG_ARGS; then
            echo -n "OK"
            RETVAL=0
        fi
    else
        daemon --check $SERVICE $PROCESS -d -l quiet $CONFIG_ARGS
    fi
    RETVAL=$?
    echo
    return $RETVAL
}
 
stop() {
    echo -n "Stopping salt-master daemon: "
    if [ -f $SUSE_RELEASE ]; then
        killproc -TERM $PROCESS
        rc_status -v
    elif [ -f $DEBIAN_VERSION ]; then
        # Added this since Debian's start-stop-daemon doesn't support spawned processes
        if ps aux | grep "$PYTHON[ ]$PROCESS" 2>&1 > /dev/null; then
            ps aux | grep "$PYTHON[ ]$PROCESS" | awk '{ print $2 }' | xargs kill
            echo -n "OK"
            RETVAL=0
        else
            echo -n "Daemon is not started"
            RETVAL=1
        fi
    else
        killproc $PROCESS
    fi
    RETVAL=$?
    echo
}
 
restart() {
    stop
    sleep 1
    start
}
 
# See how we were called.
case "$1" in
    start|stop|restart)
        $1
        ;;
    status)
        if [ -f $SUSE_RELEASE ]; then
            echo -n "Checking for service salt-master "
            checkproc $PROCESS
            rc_status -v
        elif [ -f $DEBIAN_VERSION ]; then
            if ps aux | grep "$PYTHON[ ]$PROCESS" 2>&1 > /dev/null; then
                RETVAL=0
                echo "salt-master is running."
            else
                RETVAL=1
                echo "salt-master is stopped."
            fi
        else
            status $PROCESS
            RETVAL=$?
        fi
        ;;
    condrestart)
        [ -f $LOCKFILE ] && restart || :
        ;;
    reload)
        echo "can't reload configuration, you have to restart it"
        RETVAL=$?
        ;;
    *)
        echo $"Usage: $0 {start|stop|status|restart|condrestart|reload}"
        exit 1
        ;;
esac
exit $RETVAL
EOF

chmod +x /etc/init.d/salt-master

test -d /etc/salt/minion.d/ || mkdir -p /etc/salt/minion.d/

cat << "EOF" > /etc/salt/minion
##### Primary configuration settings #####
##########################################

# Per default the minion will automatically include all config files
# from minion.d/*.conf (minion.d is a directory in the same directory
# as the main minion config file).
#default_include: minion.d/*.conf

# Set the location of the salt master server, if the master server cannot be
# resolved, then the minion will fail to start.
#master: salt

# Set whether the minion should connect to the master via IPv6
#ipv6: False

# Set the number of seconds to wait before attempting to resolve
# the master hostname if name resolution fails. Defaults to 30 seconds.
# Set to zero if the minion should shutdown and not retry.
# retry_dns: 30

# Set the port used by the master reply and authentication server
#master_port: 4506

# The user to run salt
#user: root

# Specify the location of the daemon process ID file
#pidfile: /var/run/salt-minion.pid

# The root directory prepended to these options: pki_dir, cachedir, log_file,
# sock_dir, pidfile.
#root_dir: /

# The directory to store the pki information in
#pki_dir: /etc/salt/pki/minion

# Explicitly declare the id for this minion to use, if left commented the id
# will be the hostname as returned by the python call: socket.getfqdn()
# Since salt uses detached ids it is possible to run multiple minions on the
# same machine but with different ids, this can be useful for salt compute
# clusters.
#id:

# Append a domain to a hostname in the event that it does not exist.  This is
# useful for systems where socket.getfqdn() does not actually result in a
# FQDN (for instance, Solaris).
#append_domain:

# Custom static grains for this minion can be specified here and used in SLS
# files just like all other grains. This example sets 4 custom grains, with
# the 'roles' grain having two values that can be matched against:
#grains:
#  roles:
#    - webserver
#    - memcache
#  deployment: datacenter4
#  cabinet: 13
#  cab_u: 14-15

# Where cache data goes
#cachedir: /var/cache/salt/minion

# Verify and set permissions on configuration directories at startup
#verify_env: True

# The minion can locally cache the return data from jobs sent to it, this
# can be a good way to keep track of jobs the minion has executed
# (on the minion side). By default this feature is disabled, to enable
# set cache_jobs to True
#cache_jobs: False

# set the directory used to hold unix sockets
#sock_dir: /var/run/salt/minion

# Set the default outputter used by the salt-call command. The default is
# "nested"
#output: nested
#
# By default output is colored, to disable colored output set the color value
# to False
#color: True

# Backup files that are replaced by file.managed and file.recurse under
# 'cachedir'/file_backups relative to their original location and appended
# with a timestamp. The only valid setting is "minion". Disabled by default.
#
# Alternatively this can be specified for each file in state files:
#
# /etc/ssh/sshd_config:
#   file.managed:
#     - source: salt://ssh/sshd_config
#     - backup: minion
#
#backup_mode: minion

# When waiting for a master to accept the minion's public key, salt will
# continuously attempt to reconnect until successful. This is the time, in
# seconds, between those reconnection attempts.
#acceptance_wait_time: 10

# If this is nonzero, the time between reconnection attempts will increase by
# acceptance_wait_time seconds per iteration, up to this maximum. If this is
# set to zero, the time between reconnection attempts will stay constant.
#acceptance_wait_time_max: 0

# If the master rejects the minion's public key, retry instead exiting. Rejected keys
# # will be handled the same as waiting on acceptance.
#rejected_retry: False

# When the master key changes, the minion will try to re-auth itself to receive
# the new master key. In larger environments this can cause a SYN flood on the
# master because all minions try to re-auth immediately. To prevent this and
# have a minion wait for a random amount of time, use this optional parameter.
# The wait-time will be a random number of seconds between
# 0 and the defined value.
#random_reauth_delay: 60

# When waiting for a master to accept the minion's public key, salt will
# continuously attempt to reconnect until successful. This is the timeout value,
# in seconds, for each individual attempt. After this timeout expires, the minion
# will wait for acceptance_wait_time seconds before trying again.
# Unless your master is under unusually heavy load, this should be left at the default.
#auth_timeout: 3


# If you don't have any problems with syn-floods, dont bother with the
# three recon_* settings described below, just leave the defaults!
#
# The ZeroMQ pull-socket that binds to the masters publishing interface tries
# to reconnect immediately, if the socket is disconnected (for example if
# the master processes are restarted). In large setups this will have all
# minions reconnect immediately which might flood the master (the ZeroMQ-default
# is usually a 100ms delay). To prevent this, these three recon_* settings
# can be used.
#
# recon_default: the interval in milliseconds that the socket should wait before
#                trying to reconnect to the master (100ms = 1 second)
#
# recon_max: the maximum time a socket should wait. each interval the time to wait
#            is calculated by doubling the previous time. if recon_max is reached,
#            it starts again at recon_default. Short example:
#
#            reconnect 1: the socket will wait 'recon_default' milliseconds
#            reconnect 2: 'recon_default' * 2
#            reconnect 3: ('recon_default' * 2) * 2
#            reconnect 4: value from previous interval * 2
#            reconnect 5: value from previous interval * 2
#            reconnect x: if value >= recon_max, it starts again with recon_default
#
# recon_randomize: generate a random wait time on minion start. The wait time will
#                  be a random value between recon_default and recon_default +
#                  recon_max. Having all minions reconnect with the same recon_default
#                  and recon_max value kind of defeats the purpose of being able to
#                  change these settings. If all minions have the same values and your
#                  setup is quite large (several thousand minions), they will still
#                  flood the master. The desired behaviour is to have timeframe within
#                  all minions try to reconnect.

# Example on how to use these settings:
# The goal: have all minions reconnect within a 60 second timeframe on a disconnect
#
# The settings:
#recon_default: 1000
#recon_max: 59000
#recon_randomize: True
#
# Each minion will have a randomized reconnect value between 'recon_default'
# and 'recon_default + recon_max', which in this example means between 1000ms
# 60000ms (or between 1 and 60 seconds). The generated random-value will be
# doubled after each attempt to reconnect. Lets say the generated random
# value is 11 seconds (or 11000ms).
#
# reconnect 1: wait 11 seconds
# reconnect 2: wait 22 seconds
# reconnect 3: wait 33 seconds
# reconnect 4: wait 44 seconds
# reconnect 5: wait 55 seconds
# reconnect 6: wait time is bigger than 60 seconds (recon_default + recon_max)
# reconnect 7: wait 11 seconds
# reconnect 8: wait 22 seconds
# reconnect 9: wait 33 seconds
# reconnect x: etc.
#
# In a setup with ~6000 thousand hosts these settings would average the reconnects
# to about 100 per second and all hosts would be reconnected within 60 seconds.
#recon_default: 100
#recon_max: 5000
#recon_randomize: False

# The loop_interval sets how long in seconds the minion will wait between
# evaluating the scheduler and running cleanup tasks. This defaults to a
# sane 60 seconds, but if the minion scheduler needs to be evaluated more
# often lower this value
#loop_interval: 60

# The grains_refresh_every setting allows for a minion to periodically check
# its grains to see if they have changed and, if so, to inform the master
# of the new grains. This operation is moderately expensive, therefore
# care should be taken not to set this value too low.
#
# Note: This value is expressed in __minutes__!
#
# A value of 10 minutes is a reasonable default.
#
# If the value is set to zero, this check is disabled.
#grains_refresh_every = 1

# Cache grains on the minion. Default is False.
# grains_cache: False

# Grains cache expiration, in seconds. If the cache file is older than this
# number of seconds then the grains cache will be dumped and fully re-populated
# with fresh data. Defaults to 5 minutes. Will have no effect if 'grains_cache'
# is not enabled.
# grains_cache_expiration: 300


# When healing, a dns_check is run. This is to make sure that the originally
# resolved dns has not changed. If this is something that does not happen in
# your environment, set this value to False.
#dns_check: True

# Windows platforms lack posix IPC and must rely on slower TCP based inter-
# process communications. Set ipc_mode to 'tcp' on such systems
#ipc_mode: ipc
#
# Overwrite the default tcp ports used by the minion when in tcp mode
#tcp_pub_port: 4510
#tcp_pull_port: 4511

# The minion can include configuration from other files. To enable this,
# pass a list of paths to this option. The paths can be either relative or
# absolute; if relative, they are considered to be relative to the directory
# the main minion configuration file lives in (this file). Paths can make use
# of shell-style globbing. If no files are matched by a path passed to this
# option then the minion will log a warning message.
#
#
# Include a config file from some other path:
# include: /etc/salt/extra_config
#
# Include config from several files and directories:
#include:
#  - /etc/salt/extra_config
#  - /etc/roles/webserver

#####   Minion module management     #####
##########################################
# Disable specific modules. This allows the admin to limit the level of
# access the master has to the minion
#disable_modules: [cmd,test]
#disable_returners: []
#
# Modules can be loaded from arbitrary paths. This enables the easy deployment
# of third party modules. Modules for returners and minions can be loaded.
# Specify a list of extra directories to search for minion modules and
# returners. These paths must be fully qualified!
#module_dirs: []
#returner_dirs: []
#states_dirs: []
#render_dirs: []
#
# A module provider can be statically overwritten or extended for the minion
# via the providers option, in this case the default module will be
# overwritten by the specified module. In this example the pkg module will
# be provided by the yumpkg5 module instead of the system default.
#
#providers:
#  pkg: yumpkg5
#
# Enable Cython modules searching and loading. (Default: False)
#cython_enable: False
#
#
#
# Specify a max size (in bytes) for modules on import
# this feature is currently only supported on *nix OSs and requires psutil
# modules_max_memory: -1



#####    State Management Settings    #####
###########################################
# The state management system executes all of the state templates on the minion
# to enable more granular control of system state management. The type of
# template and serialization used for state management needs to be configured
# on the minion, the default renderer is yaml_jinja. This is a yaml file
# rendered from a jinja template, the available options are:
# yaml_jinja
# yaml_mako
# yaml_wempy
# json_jinja
# json_mako
# json_wempy
#
#renderer: yaml_jinja
#
# The failhard option tells the minions to stop immediately after the first
# failure detected in the state execution, defaults to False
#failhard: False
#
# autoload_dynamic_modules Turns on automatic loading of modules found in the
# environments on the master. This is turned on by default, to turn of
# autoloading modules when states run set this value to False
#autoload_dynamic_modules: True
#
# clean_dynamic_modules keeps the dynamic modules on the minion in sync with
# the dynamic modules on the master, this means that if a dynamic module is
# not on the master it will be deleted from the minion. By default this is
# enabled and can be disabled by changing this value to False
#clean_dynamic_modules: True
#
# Normally the minion is not isolated to any single environment on the master
# when running states, but the environment can be isolated on the minion side
# by statically setting it. Remember that the recommended way to manage
# environments is to isolate via the top file.
#environment: None
#
# If using the local file directory, then the state top file name needs to be
# defined, by default this is top.sls.
#state_top: top.sls
#
# Run states when the minion daemon starts. To enable, set startup_states to:
# 'highstate' -- Execute state.highstate
# 'sls' -- Read in the sls_list option and execute the named sls files
# 'top' -- Read top_file option and execute based on that file on the Master
#startup_states: ''
#
# list of states to run when the minion starts up if startup_states is 'sls'
#sls_list:
#  - edit.vim
#  - hyper
#
# top file to execute if startup_states is 'top'
#top_file: ''

#####     File Directory Settings    #####
##########################################
# The Salt Minion can redirect all file server operations to a local directory,
# this allows for the same state tree that is on the master to be used if
# copied completely onto the minion. This is a literal copy of the settings on
# the master but used to reference a local directory on the minion.

# Set the file client. The client defaults to looking on the master server for
# files, but can be directed to look at the local file directory setting
# defined below by setting it to local.
#file_client: remote

# The file directory works on environments passed to the minion, each environment
# can have multiple root directories, the subdirectories in the multiple file
# roots cannot match, otherwise the downloaded files will not be able to be
# reliably ensured. A base environment is required to house the top file.
# Example:
# file_roots:
#   base:
#     - /srv/salt/
#   dev:
#     - /srv/salt/dev/services
#     - /srv/salt/dev/states
#   prod:
#     - /srv/salt/prod/services
#     - /srv/salt/prod/states
#
#file_roots:
#  base:
#    - /srv/salt

# By default, the Salt fileserver recurses fully into all defined environments
# to attempt to find files. To limit this behavior so that the fileserver only
# traverses directories with SLS files and special Salt directories like _modules,
# enable the option below. This might be useful for installations where a file root
# has a very large number of files and performance is negatively impacted.
#
# Default is False.
#
# fileserver_limit_traversal: False

# The hash_type is the hash to use when discovering the hash of a file in
# the local fileserver. The default is md5, but sha1, sha224, sha256, sha384
# and sha512 are also supported.
#hash_type: md5

# The Salt pillar is searched for locally if file_client is set to local. If
# this is the case, and pillar data is defined, then the pillar_roots need to
# also be configured on the minion:
#pillar_roots:
#  base:
#    - /srv/pillar

######        Security settings       #####
###########################################
# Enable "open mode", this mode still maintains encryption, but turns off
# authentication, this is only intended for highly secure environments or for
# the situation where your keys end up in a bad state. If you run in open mode
# you do so at your own risk!
#open_mode: False

# Enable permissive access to the salt keys.  This allows you to run the
# master or minion as root, but have a non-root group be given access to
# your pki_dir.  To make the access explicit, root must belong to the group
# you've given access to. This is potentially quite insecure.
#permissive_pki_access: False

# The state_verbose and state_output settings can be used to change the way
# state system data is printed to the display. By default all data is printed.
# The state_verbose setting can be set to True or False, when set to False
# all data that has a result of True and no changes will be suppressed.
#state_verbose: True
#
# The state_output setting changes if the output is the full multi line
# output for each changed state if set to 'full', but if set to 'terse'
# the output will be shortened to a single line.
#state_output: full
#
# Fingerprint of the master public key to double verify the master is valid,
# the master fingerprint can be found by running "salt-key -F master" on the
# salt master.
#master_finger: ''

######         Thread settings        #####
###########################################
# Disable multiprocessing support, by default when a minion receives a
# publication a new process is spawned and the command is executed therein.
#multiprocessing: True

#####         Logging settings       #####
##########################################
# The location of the minion log file
# The minion log can be sent to a regular file, local path name, or network
# location. Remote logging works best when configured to use rsyslogd(8) (e.g.:
# ``file:///dev/log``), with rsyslogd(8) configured for network logging. The URI
# format is: <file|udp|tcp>://<host|socketpath>:<port-if-required>/<log-facility>
#log_file: /var/log/salt/minion
#log_file: file:///dev/log
#log_file: udp://loghost:10514
#
#log_file: /var/log/salt/minion
#key_logfile: /var/log/salt/key
#
# The level of messages to send to the console.
# One of 'garbage', 'trace', 'debug', info', 'warning', 'error', 'critical'.
# Default: 'warning'
#log_level: warning
#
# The level of messages to send to the log file.
# One of 'garbage', 'trace', 'debug', info', 'warning', 'error', 'critical'.
# Default: 'warning'
#log_level_logfile:

# The date and time format used in log messages. Allowed date/time formating
# can be seen here: http://docs.python.org/library/time.html#time.strftime
#log_datefmt: '%H:%M:%S'
#log_datefmt_logfile: '%Y-%m-%d %H:%M:%S'
#
# The format of the console logging messages. Allowed formatting options can
# be seen here: http://docs.python.org/library/logging.html#logrecord-attributes
#log_fmt_console: '[%(levelname)-8s] %(message)s'
#log_fmt_logfile: '%(asctime)s,%(msecs)03.0f [%(name)-17s][%(levelname)-8s] %(message)s'
#
# This can be used to control logging levels more specificically.  This
# example sets the main salt library at the 'warning' level, but sets
# 'salt.modules' to log at the 'debug' level:
#   log_granular_levels:
#     'salt': 'warning',
#     'salt.modules': 'debug'
#
#log_granular_levels: {}

######      Module configuration      #####
###########################################
# Salt allows for modules to be passed arbitrary configuration data, any data
# passed here in valid yaml format will be passed on to the salt minion modules
# for use. It is STRONGLY recommended that a naming convention be used in which
# the module name is followed by a . and then the value. Also, all top level
# data must be applied via the yaml dict construct, some examples:
#
# You can specify that all modules should run in test mode:
#test: True
#
# A simple value for the test module:
#test.foo: foo
#
# A list for the test module:
#test.bar: [baz,quo]
#
# A dict for the test module:
#test.baz: {spam: sausage, cheese: bread}


######      Update settings          ######
###########################################
# Using the features in Esky, a salt minion can both run as a frozen app and
# be updated on the fly. These options control how the update process
# (saltutil.update()) behaves.
#
# The url for finding and downloading updates. Disabled by default.
#update_url: False
#
# The list of services to restart after a successful update. Empty by default.
#update_restart_services: []


######      Keepalive settings        ######
############################################
# ZeroMQ now includes support for configuring SO_KEEPALIVE if supported by
# the OS. If connections between the minion and the master pass through
# a state tracking device such as a firewall or VPN gateway, there is
# the risk that it could tear down the connection the master and minion
# without informing either party that their connection has been taken away.
# Enabling TCP Keepalives prevents this from happening.
#
# Overall state of TCP Keepalives, enable (1 or True), disable (0 or False)
# or leave to the OS defaults (-1), on Linux, typically disabled. Default True, enabled.
#tcp_keepalive: True
#
# How long before the first keepalive should be sent in seconds. Default 300
# to send the first keepalive after 5 minutes, OS default (-1) is typically 7200 seconds
# on Linux see /proc/sys/net/ipv4/tcp_keepalive_time.
#tcp_keepalive_idle: 300
#
# How many lost probes are needed to consider the connection lost. Default -1
# to use OS defaults, typically 9 on Linux, see /proc/sys/net/ipv4/tcp_keepalive_probes.
#tcp_keepalive_cnt: -1
#
# How often, in seconds, to send keepalives after the first one. Default -1 to
# use OS defaults, typically 75 seconds on Linux, see
# /proc/sys/net/ipv4/tcp_keepalive_intvl.
#tcp_keepalive_intvl: -1


######      Windows Software settings ######
############################################
# Location of the repository cache file on the master
#win_repo_cachefile: 'salt://win/repo/winrepo.p'
EOF

cat << "EOF" > /etc/salt/master
##### Primary configuration settings #####
##########################################
# This configuration file is used to manage the behavior of the Salt Master
# Values that are commented out but have no space after the comment are
# defaults that need not be set in the config. If there is a space after the
# comment that the value is presented as an example and is not the default.

# Per default, the master will automatically include all config files
# from master.d/*.conf (master.d is a directory in the same directory
# as the main master config file)
#default_include: master.d/*.conf

# The address of the interface to bind to
#interface: 0.0.0.0

# Whether the master should listen for IPv6 connections. If this is set to True,
# the interface option must be adjusted too (for example: "interface: '::'")
#ipv6: False

# The tcp port used by the publisher
#publish_port: 4505

# The user under which the salt master will run. Salt will update all
# permissions to allow the specified user to run the master. The exception is
# the job cache, which must be deleted if this user is changed.  If the
# modified files cause conflicts set verify_env to False.
#user: root

# Max open files
# Each minion connecting to the master uses AT LEAST one file descriptor, the
# master subscription connection. If enough minions connect you might start
# seeing on the console(and then salt-master crashes):
#   Too many open files (tcp_listener.cpp:335)
#   Aborted (core dumped)
#
# By default this value will be the one of `ulimit -Hn`, ie, the hard limit for
# max open files.
#
# If you wish to set a different value than the default one, uncomment and
# configure this setting. Remember that this value CANNOT be higher than the
# hard limit. Raising the hard limit depends on your OS and/or distribution,
# a good way to find the limit is to search the internet for(for example):
#   raise max open files hard limit debian
#
#max_open_files: 100000

# The number of worker threads to start, these threads are used to manage
# return calls made from minions to the master, if the master seems to be
# running slowly, increase the number of threads
#worker_threads: 5

# The port used by the communication interface. The ret (return) port is the
# interface used for the file server, authentication, job returnes, etc.
#ret_port: 4506

# Specify the location of the daemon process ID file
#pidfile: /var/run/salt-master.pid

# The root directory prepended to these options: pki_dir, cachedir,
# sock_dir, log_file, autosign_file, autoreject_file, extension_modules,
# key_logfile, pidfile.
#root_dir: /

# Directory used to store public key data
#pki_dir: /etc/salt/pki/master

# Directory to store job and cache data
#cachedir: /var/cache/salt/master

# Verify and set permissions on configuration directories at startup
#verify_env: True

# Set the number of hours to keep old job information in the job cache
#keep_jobs: 24

# Set the default timeout for the salt command and api, the default is 5
# seconds
#timeout: 5

# The loop_interval option controls the seconds for the master's maintinance
# process check cycle. This process updates file server backends, cleans the
# job cache and executes the scheduler.
#loop_interval: 60

# Set the default outputter used by the salt command. The default is "nested"
#output: nested

# By default output is colored, to disable colored output set the color value
# to False
#color: True

# Set the directory used to hold unix sockets
#sock_dir: /var/run/salt/master

# The master can take a while to start up when lspci and/or dmidecode is used
# to populate the grains for the master. Enable if you want to see GPU hardware
# data for your master.
#
# enable_gpu_grains: False

# The master maintains a job cache, while this is a great addition it can be
# a burden on the master for larger deployments (over 5000 minions).
# Disabling the job cache will make previously executed jobs unavailable to
# the jobs system and is not generally recommended.
#
#job_cache: True

# Cache minion grains and pillar data in the cachedir.
#minion_data_cache: True

# The master can include configuration from other files. To enable this,
# pass a list of paths to this option. The paths can be either relative or
# absolute; if relative, they are considered to be relative to the directory
# the main master configuration file lives in (this file). Paths can make use
# of shell-style globbing. If no files are matched by a path passed to this
# option then the master will log a warning message.
#
#
# Include a config file from some other path:
#include: /etc/salt/extra_config
#
# Include config from several files and directories:
#include:
#  - /etc/salt/extra_config


#####        Security settings       #####
##########################################
# Enable "open mode", this mode still maintains encryption, but turns off
# authentication, this is only intended for highly secure environments or for
# the situation where your keys end up in a bad state. If you run in open mode
# you do so at your own risk!
#open_mode: False

# Enable auto_accept, this setting will automatically accept all incoming
# public keys from the minions. Note that this is insecure.
#auto_accept: False

# If the autosign_file is specified, incoming keys specified in the
# autosign_file will be automatically accepted. This is insecure.  Regular
# expressions as well as globing lines are supported.
#autosign_file: /etc/salt/autosign.conf

# Works like autosign_file, but instead allows you to specify minion IDs for
# which keys will automatically be rejected. Will override both membership in
# the autosign_file and the auto_accept setting.
#autoreject_file: /etc/salt/autoreject.conf

# Enable permissive access to the salt keys.  This allows you to run the
# master or minion as root, but have a non-root group be given access to
# your pki_dir.  To make the access explicit, root must belong to the group
# you've given access to.  This is potentially quite insecure.
# If an autosign_file is specified, enabling permissive_pki_access will allow group access
# to that specific file.
#permissive_pki_access: False

# Allow users on the master access to execute specific commands on minions.
# This setting should be treated with care since it opens up execution
# capabilities to non root users. By default this capability is completely
# disabled.
#
#client_acl:
#  larry:
#    - test.ping
#    - network.*
#

# Blacklist any of the following users or modules
#
# This example would blacklist all non sudo users, including root from
# running any commands. It would also blacklist any use of the "cmd"
# module.
# This is completely disabled by default.
#
#client_acl_blacklist:
#  users:
#    - root
#    - '^(?!sudo_).*$'   #  all non sudo users
#  modules:
#    - cmd

# The external auth system uses the Salt auth modules to authenticate and
# validate users to access areas of the Salt system.
#
#external_auth:
#  pam:
#    fred:
#      - test.*
#

# Time (in seconds) for a newly generated token to live. Default: 12 hours
#token_expire: 43200

# Allow minions to push files to the master. This is disabled by default, for
# security purposes.
#file_recv: False

# Set a hard-limit on the size of the files that can be pushed to the master.
# It will be interpreted as megabytes.
# Default: 100
#file_recv_max_size: 100

# Signature verification on messages published from the master.
# This causes the master to cryptographically sign all messages published to its event
# bus, and minions then verify that signature before acting on the message.
#
# This is False by default.
#
# Note that to facilitate interoperability with masters and minions that are different
# versions, if sign_pub_messages is True but a message is received by a minion with
# no signature, it will still be accepted, and a warning message will be logged.
# Conversely, if sign_pub_messages is False, but a minion receives a signed
# message it will be accepted, the signature will not be checked, and a warning message
# will be logged.  This behavior will go away in Salt 0.17.6 (or Hydrogen RC1, whichever
# comes first) and these two situations will cause minion to throw an exception and
# drop the message.
#
# sign_pub_messages: False

#####    Master Module Management    #####
##########################################
# Manage how master side modules are loaded

# Add any additional locations to look for master runners
#runner_dirs: []

# Enable Cython for master side modules
#cython_enable: False


#####      State System settings     #####
##########################################
# The state system uses a "top" file to tell the minions what environment to
# use and what modules to use. The state_top file is defined relative to the
# root of the base environment as defined in "File Server settings" below.
#state_top: top.sls

# The master_tops option replaces the external_nodes option by creating
# a plugable system for the generation of external top data. The external_nodes
# option is deprecated by the master_tops option.
# To gain the capabilities of the classic external_nodes system, use the
# following configuration:
# master_tops:
#   ext_nodes: <Shell command which returns yaml>
#
#master_tops: {}

# The external_nodes option allows Salt to gather data that would normally be
# placed in a top file. The external_nodes option is the executable that will
# return the ENC data. Remember that Salt will look for external nodes AND top
# files and combine the results if both are enabled!
#external_nodes: None

# The renderer to use on the minions to render the state data
#renderer: yaml_jinja

# The Jinja renderer can strip extra carriage returns and whitespace
# See http://jinja.pocoo.org/docs/api/#high-level-api
#
# If this is set to True the first newline after a Jinja block is removed
# (block, not variable tag!). Defaults to False, corresponds to the Jinja
# environment init variable "trim_blocks".
# jinja_trim_blocks: False
#
# If this is set to True leading spaces and tabs are stripped from the start
# of a line to a block. Defaults to False, corresponds to the Jinja
# environment init variable "lstrip_blocks".
# jinja_lstrip_blocks: False

# The failhard option tells the minions to stop immediately after the first
# failure detected in the state execution, defaults to False
#failhard: False

# The state_verbose and state_output settings can be used to change the way
# state system data is printed to the display. By default all data is printed.
# The state_verbose setting can be set to True or False, when set to False
# all data that has a result of True and no changes will be suppressed.
#state_verbose: True

# The state_output setting changes if the output is the full multi line
# output for each changed state if set to 'full', but if set to 'terse'
# the output will be shortened to a single line.  If set to 'mixed', the output
# will be terse unless a state failed, in which case that output will be full.
#state_output: full


#####      File Server settings      #####
##########################################
# Salt runs a lightweight file server written in zeromq to deliver files to
# minions. This file server is built into the master daemon and does not
# require a dedicated port.

# The file server works on environments passed to the master, each environment
# can have multiple root directories, the subdirectories in the multiple file
# roots cannot match, otherwise the downloaded files will not be able to be
# reliably ensured. A base environment is required to house the top file.
# Example:
# file_roots:
#   base:
#     - /srv/salt/
#   dev:
#     - /srv/salt/dev/services
#     - /srv/salt/dev/states
#   prod:
#     - /srv/salt/prod/services
#     - /srv/salt/prod/states

#file_roots:
#  base:
#    - /srv/salt

# The hash_type is the hash to use when discovering the hash of a file on
# the master server. The default is md5, but sha1, sha224, sha256, sha384
# and sha512 are also supported.
#hash_type: md5

# The buffer size in the file server can be adjusted here:
#file_buffer_size: 1048576

# A regular expression (or a list of expressions) that will be matched
# against the file path before syncing the modules and states to the minions.
# This includes files affected by the file.recurse state.
# For example, if you manage your custom modules and states in subversion
# and don't want all the '.svn' folders and content synced to your minions,
# you could set this to '/\.svn($|/)'. By default nothing is ignored.
#
#file_ignore_regex:
#  - '/\.svn($|/)'
#  - '/\.git($|/)'

# A file glob (or list of file globs) that will be matched against the file
# path before syncing the modules and states to the minions. This is similar
# to file_ignore_regex above, but works on globs instead of regex. By default
# nothing is ignored.
#
# file_ignore_glob:
#  - '*.pyc'
#  - '*/somefolder/*.bak'
#  - '*.swp'

# File Server Backend
# Salt supports a modular fileserver backend system, this system allows
# the salt master to link directly to third party systems to gather and
# manage the files available to minions. Multiple backends can be
# configured and will be searched for the requested file in the order in which
# they are defined here. The default setting only enables the standard backend
# "roots" which uses the "file_roots" option.
#
#fileserver_backend:
#  - roots
#
# To use multiple backends list them in the order they are searched:
#
#fileserver_backend:
#  - git
#  - roots
#
# Uncomment the line below if you do not want the file_server to follow
# symlinks when walking the filesystem tree. This is set to True
# by default. Currently this only applies to the default roots
# fileserver_backend.
#
#fileserver_followsymlinks: False
#
# Uncomment the line below if you do not want symlinks to be
# treated as the files they are pointing to. By default this is set to
# False. By uncommenting the line below, any detected symlink while listing
# files on the Master will not be returned to the Minion.
#
#fileserver_ignoresymlinks: True
#
# By default, the Salt fileserver recurses fully into all defined environments
# to attempt to find files. To limit this behavior so that the fileserver only
# traverses directories with SLS files and special Salt directories like _modules,
# enable the option below. This might be useful for installations where a file root
# has a very large number of files and performance is impacted. Default is False.
#
# fileserver_limit_traversal: False
#
# The fileserver can fire events off every time the fileserver is updated,
# these are disabled by default, but can be easily turned on by setting this
# flag to True
#fileserver_events: False
#
# Git fileserver backend configuration
# When using the git fileserver backend at least one git remote needs to be
# defined. The user running the salt master will need read access to the repo.
#
#gitfs_remotes:
#  - git://github.com/saltstack/salt-states.git
#  - file:///var/git/saltmaster
#
# The gitfs_ssl_verify option specifies whether to ignore ssl certificate
# errors when contacting the gitfs backend. You might want to set this to
# false if you're using a git backend that uses a self-signed certificate but
# keep in mind that setting this flag to anything other than the default of True
# is a security concern, you may want to try using the ssh transport.
#gitfs_ssl_verify: True
#
# The repos will be searched in order to find the file requested by a client
# and the first repo to have the file will return it.
# When using the git backend branches and tags are translated into salt
# environments.
# Note:  file:// repos will be treated as a remote, so refs you want used must
# exist in that repo as *local* refs.
#
# The gitfs_root option gives the ability to serve files from a subdirectory
# within the repository. The path is defined relative to the root of the
# repository and defaults to the repository root.
#gitfs_root: somefolder/otherfolder


#####         Pillar settings        #####
##########################################
# Salt Pillars allow for the building of global data that can be made selectively
# available to different minions based on minion grain filtering. The Salt
# Pillar is laid out in the same fashion as the file server, with environments,
# a top file and sls files. However, pillar data does not need to be in the
# highstate format, and is generally just key/value pairs.

#pillar_roots:
#  base:
#    - /srv/pillar

#ext_pillar:
#  - hiera: /etc/hiera.yaml
#  - cmd_yaml: cat /etc/salt/yaml

# The pillar_gitfs_ssl_verify option specifies whether to ignore ssl certificate
# errors when contacting the pillar gitfs backend. You might want to set this to
# false if you're using a git backend that uses a self-signed certificate but
# keep in mind that setting this flag to anything other than the default of True
# is a security concern, you may want to try using the ssh transport.
#pillar_gitfs_ssl_verify: True

# The pillar_opts option adds the master configuration file data to a dict in
# the pillar called "master". This is used to set simple configurations in the
# master config file that can then be used on minions.
#pillar_opts: True


#####          Syndic settings       #####
##########################################
# The Salt syndic is used to pass commands through a master from a higher
# master. Using the syndic is simple, if this is a master that will have
# syndic servers(s) below it set the "order_masters" setting to True, if this
# is a master that will be running a syndic daemon for passthrough the
# "syndic_master" setting needs to be set to the location of the master server
# to receive commands from.

# Set the order_masters setting to True if this master will command lower
# masters' syndic interfaces.
#order_masters: False

# If this master will be running a salt syndic daemon, syndic_master tells
# this master where to receive commands from.
#syndic_master: masterofmaster

# This is the 'ret_port' of the MasterOfMaster
#syndic_master_port: 4506

# PID file of the syndic daemon
#syndic_pidfile: /var/run/salt-syndic.pid

# LOG file of the syndic daemon
#syndic_log_file: syndic.log

#####      Peer Publish settings     #####
##########################################
# Salt minions can send commands to other minions, but only if the minion is
# allowed to. By default "Peer Publication" is disabled, and when enabled it
# is enabled for specific minions and specific commands. This allows secure
# compartmentalization of commands based on individual minions.

# The configuration uses regular expressions to match minions and then a list
# of regular expressions to match functions. The following will allow the
# minion authenticated as foo.example.com to execute functions from the test
# and pkg modules.
#
#peer:
#  foo.example.com:
#    - test.*
#    - pkg.*
#
# This will allow all minions to execute all commands:
#
#peer:
#  .*:
#    - .*
#
# This is not recommended, since it would allow anyone who gets root on any
# single minion to instantly have root on all of the minions!

# Minions can also be allowed to execute runners from the salt master.
# Since executing a runner from the minion could be considered a security risk,
# it needs to be enabled. This setting functions just like the peer setting
# except that it opens up runners instead of module functions.
#
# All peer runner support is turned off by default and must be enabled before
# using. This will enable all peer runners for all minions:
#
#peer_run:
#  .*:
#    - .*
#
# To enable just the manage.up runner for the minion foo.example.com:
#
#peer_run:
#  foo.example.com:
#    - manage.up

#####         Mine settings     #####
##########################################
# Restrict mine.get access from minions. By default any minion has a full access
# to get all mine data from master cache. In acl definion below, only pcre matches
# are allowed.
#
# mine_get:
#   .*:
#     - .*
#
# Example below enables minion foo.example.com to get  'network.interfaces' mine data only
# , minions web* to get all network.* and disk.* mine data and all other minions won't get
# any mine data.
#
# mine_get:
#   foo.example.com:
#     - network.inetrfaces
#   web.*:
#     - network.*
#     - disk.*

#####         Logging settings       #####
##########################################
# The location of the master log file
# The master log can be sent to a regular file, local path name, or network
# location. Remote logging works best when configured to use rsyslogd(8) (e.g.:
# ``file:///dev/log``), with rsyslogd(8) configured for network logging. The URI
# format is: <file|udp|tcp>://<host|socketpath>:<port-if-required>/<log-facility>
#log_file: /var/log/salt/master
#log_file: file:///dev/log
#log_file: udp://loghost:10514

#log_file: /var/log/salt/master
#key_logfile: /var/log/salt/key

# The level of messages to send to the console.
# One of 'garbage', 'trace', 'debug', info', 'warning', 'error', 'critical'.
#log_level: warning

# The level of messages to send to the log file.
# One of 'garbage', 'trace', 'debug', info', 'warning', 'error', 'critical'.
#log_level_logfile: warning

# The date and time format used in log messages. Allowed date/time formating
# can be seen here: http://docs.python.org/library/time.html#time.strftime
#log_datefmt: '%H:%M:%S'
#log_datefmt_logfile: '%Y-%m-%d %H:%M:%S'

# The format of the console logging messages. Allowed formatting options can
# be seen here: http://docs.python.org/library/logging.html#logrecord-attributes
#log_fmt_console: '[%(levelname)-8s] %(message)s'
#log_fmt_logfile: '%(asctime)s,%(msecs)03.0f [%(name)-17s][%(levelname)-8s] %(message)s'

# This can be used to control logging levels more specificically.  This
# example sets the main salt library at the 'warning' level, but sets
# 'salt.modules' to log at the 'debug' level:
#   log_granular_levels:
#     'salt': 'warning',
#     'salt.modules': 'debug'
#
#log_granular_levels: {}


#####         Node Groups           #####
##########################################
# Node groups allow for logical groupings of minion nodes.
# A group consists of a group name and a compound target.
#
#nodegroups:
#  group1: 'L@foo.domain.com,bar.domain.com,baz.domain.com and bl*.domain.com'
#  group2: 'G@os:Debian and foo.domain.com'


#####     Range Cluster settings     #####
##########################################
# The range server (and optional port) that serves your cluster information
# https://github.com/grierj/range/wiki/Introduction-to-Range-with-YAML-files
#
#range_server: range:80


#####     Windows Software Repo settings #####
##############################################
# Location of the repo on the master
#win_repo: '/srv/salt/win/repo'

# Location of the master's repo cache file
#win_repo_mastercachefile: '/srv/salt/win/repo/winrepo.p'

# List of git repositories to include with the local repo
#win_gitrepos:
#  - 'https://github.com/saltstack/salt-winrepo.git'
EOF

cat << "EOF" > /etc/salt/roster
# Sample salt-ssh config file
#web1:
#  host: 192.168.42.1 # The IP addr or DNS hostname
#  user: fred         # Remote executions will be executed as user fred
#  passwd: foobarbaz  # The password to use for login, if omitted, keys are used
#  sudo: True         # Whether to sudo to root, not enabled by default
#web2:
#  host: 192.168.42.2
EOF
cat << "EOF" > /etc/salt/cloud 
# This file should normally be installed at: /etc/salt/cloud 


##########################################
#####          VM Defaults           #####
##########################################

# Set the size of minion keys to generate, defaults to 2048
#
#keysize: 2048


# Set the default os being deployed. This sets which deployment script to
# apply. This argument is optional.
#
#script: bootstrap-salt



##########################################
#####         Logging Settings       #####
##########################################

# The location of the master log file
#
#log_file: /var/log/salt/cloud


# The level of messages to send to the console.
# One of 'garbage', 'trace', 'debug', info', 'warning', 'error', 'critical'.
#
# Default: 'info'
#
#log_level: info


# The level of messages to send to the log file.
# One of 'garbage', 'trace', 'debug', info', 'warning', 'error', 'critical'.
#
# Default: 'info'
#
#log_level_logfile: info


# The date and time format used in log messages. Allowed date/time formating
# can be seen here:
#
#	http://docs.python.org/library/time.html#time.strftime
#
#log_datefmt: '%Y-%m-%d %H:%M:%S'


# The format of the console logging messages. Allowed formatting options can
# be seen here:
#
#	http://docs.python.org/library/logging.html#logrecord-attributes
#
#log_fmt_console: '[%(levelname)-8s] %(message)s'
#log_fmt_logfile: '%(asctime)s,%(msecs)03.0f [%(name)-17s][%(levelname)-8s] %(message)s'


# Logger levels can be used to tweak specific loggers logging levels.
# For example, if you want to have the salt library at the 'warning' level,
# but you still wish to have 'salt.modules' at the 'debug' level:
#
#   log_granular_levels:
#     'salt': 'warning',
#     'salt.modules': 'debug'
#     'saltcloud': 'info'
#
#log_granular_levels: {}


##########################################
#####         Misc Defaults          #####
##########################################

# Whether or not to remove the accompnaying SSH key from the known_hosts file
# when an instance is destroyed.
#
# Default: 'False'
#
#delete_sshkeys: False
EOF
}

main () {
#DOWNLOAD FUNC FOR INSTALL
download_func

#CHECK SYSTEM AND CREATE TEMP DIR
check_system
#create_tmp_dir
set_install_cmd 'lan'

#http server
url="http://${YUM_SERVER}/shell"

files=(
install_libzmq.sh
install_pyzmq.sh
install_pycrypto.sh
install_msgpack-python.sh
)

for file in "${files[@]}"
do
	download_exec "${file}"
done

#Install salt-2014.1.10.tar.gz
PACKAGE='salt-2014.1.10.tar.gz'
create_tmp_dir
download_and_check
run_cmds '/usr/bin/python setup.py install'

#salt setting
#ln -s /usr/local/bin/salt-* /usr/bin/
mkdir -p /etc/salt &&cp conf/{master,minion} /etc/salt/
post_init
echo "#######################################
Start salt-minion:
/etc/init.d/salt-minion start
Start salt-master:
/etc/init.d/salt-master start
"
#Config:
#/etc/salt/
#Start salt-minion:
#/usr/bin/python /usr/bin/salt-minion -d
#Start salt-master:
#/usr/bin/python /usr/bin/salt-master -d"

#EXIT AND CLEAR TEMP DIR
exit_and_clear

}

main
