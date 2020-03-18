#!/bin/bash

send_mail () {
local subj="$1"
local addr="$2"

cmd="mutt -s ${subj} -e 'set realname=html_report' -e 'set content_type=\"text/html\"'"
eval "$cmd $addr"
}

mailto='mail1,mail2'

my_date=`date -d now +"%F"`
/usr/local/mk/python3/report2html.py |\
send_mail "统计报告_${my_date}" ${mailto}
