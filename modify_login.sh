#!/bin/bash

#default
#PASS_MAX_DAYS       99999
#PASS_MIN_DAYS       0
#PASS_MIN_LEN        5
#PASS_WARN_AGE       7

test -f /etc/login.defs &&\
sed -r -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/;
s/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 0/;
s/^PASS_MIN_LEN.*/PASS_MIN_LEN 8/;
s/^PASS_WARN_AGE.*/PASS_WARN_AGE 7/' /etc/login.defs
