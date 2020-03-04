#!/bin/bash

test -f /usr/lib/check_mk_agent/plugins/mk_inventory && exit

wget https://github.com/June-Wang/github4shell/raw/master/omd/mk_inventory -O /usr/lib/check_mk_agent/plugins/mk_inventory &&\
sudo chmod +x /usr/lib/check_mk_agent/plugins/mk_inventory &&\
ls -lth /usr/lib/check_mk_agent/plugins/mk_inventory
