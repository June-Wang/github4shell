#!/bin/bash

pkg='nagios-plugins-all.tar.gz'
wget https://github.com/June-Wang/github4shell/raw/master/pkg/${pkg} -O /usr/local/${pkg}

test -f /usr/local/${pkg} && cd /usr/local/ && sudo tar xzf ${pkg}
test -f /usr/local/${pkg} && rm -f /usr/local/${pkg}
