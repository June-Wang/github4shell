#!/bin/bash

yum install check-mk-agent xinetd -y
systemctl enable xinetd.service
service xinetd restart
