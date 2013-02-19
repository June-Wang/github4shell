# History format
HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "
export HISTTIMEFORMAT
shopt -s histappend
export PROMPT_COMMAND='history -n;history -a'
export HISTSIZE=1000
export HISTFILESIZE=1000

#SET TIMEOUT
TMOUT=3600

#SET LOCAL
#export LC_ALL=C

# 1.Environment variables
export EDITOR=vim
export VISUAL=vim
export LC_COLLATE="POSIX"

# 2.File creation mask
#umask 022

# 3.Terminal settings (for remote host only)
stty erase 

# 4.Display welcome message
#echo -ne "Welcome to ${HOSTNAME}. Today is `date +"%F %T"`.\n"
#echo "Today is `date`."

# 5.System information
#echo -n "System uptime:";uptime

# 6.Alias
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias vi="vim -c 'syntax on'"
alias ls='ls --color=tty --time-style=long-iso' 2>/dev/null
