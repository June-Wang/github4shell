export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "

PROMPT_COMMAND=$(history 1)
typeset -r PROMPT_COMMAND

function log2syslog
{
   declare command
   command=$BASH_COMMAND
   IP=`/sbin/ip addr list|grep -oP '\d{1,3}(\.\d{1,3}){3}'|grep -Ev '^127|255$'|head -n1`
   logger -p local1.notice -t bash2syslog -i "audit_log,$HOSTNAME,$IP,$USER,$PPID,$SSH_CLIENT,$PWD,$command"
}
trap log2syslog DEBUG
