#!/bin/bash

service exim4 stop
rm -f /var/spool/exim4/db/*
rm -f /var/spool/exim4/db/*
rm -f /var/spool/exim4/input/*
rm -f /var/spool/exim4/msglog/*
rm -f /var/log/exim4/*
service exim4 restart
