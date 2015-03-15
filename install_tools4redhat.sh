#!/bin/bash

package='bc chkconfig vim rsync lftp mawk htop iftop nmap tcpdump lsof sysstat ntpdate curl parted dnsutils'

INSTALL_CMD='yum --skip-broken --nogpgcheck'

echo -en "Install ${package} ... "
${INSTALL_CMD} install -y ${package} >/dev/null 2>&1 && echo 'Done.' || eval "echo Install ${package} fail!;exit 1"
