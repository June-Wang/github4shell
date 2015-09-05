#!/bin/bash

sed -i 's/LONGDATETIME/SHORTDATETIME/g' /usr/share/check_mk/notifications/mail
