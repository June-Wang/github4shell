#!/bin/bash

find /omd/ -type f -name "check_mk_templates.cfg"|xargs -r -i sed -i 's/\$LONGDATETIME\$/\$SHORTDATETIME\$/' '{}'
