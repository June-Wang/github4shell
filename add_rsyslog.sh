#!/bin/bash

test -d /etc/rsyslog.d &&\
echo'#SET Standard timestamp
$template myformat,"%$NOW% %TIMESTAMP:8:15% %HOSTNAME% %syslogtag% %msg%\n"
$ActionFileDefaultTemplate myformat
$template GRAYLOGRFC5424,"<%PRI%>%PROTOCOL-VERSION% %TIMESTAMP:::date-rfc3339% %HOSTNAME% %APP-NAME% %PROCID% %MSGID% %STRUCTURED-DATA% %msg%\n"
#log to syslog server
*.*            @rsyslog.server.local:514;GRAYLOGRFC5424' > /etc/rsyslog.d/10-graylog.conf

sudo service rsyslog restart
