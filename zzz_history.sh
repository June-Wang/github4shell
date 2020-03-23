export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "

PROMPT_COMMAND=$(history 1)
typeset -r PROMPT_COMMAND

function log2syslog
{
   declare command
   command=$BASH_COMMAND
   logger -p local1.notice -t bash2syslog -i "$HOSTNAME,$USER,$PPID,$SSH_CLIENT,$PWD,$command"
}
trap log2syslog DEBUG
