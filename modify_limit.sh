#!/bin/bash

limit_profile='/etc/security/limits.conf'

grep -E '^app' >/dev/null 2>&1 ${limit_profile} ||\
echo '*       soft    nofile  512000
*       hard    nofile  512000
app     soft    nproc   40960
app     hard    nproc   40960' >> /etc/security/limits.conf
