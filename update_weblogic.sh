#!/bin/bash

yum_server='x.x.x.x'
id weblogic >/dev/null 2>&1 && user_id='weblogic'
id brh >/dev/null 2>&1 && user_id='brh'

test -z "${user_id}" &&\
eval "echo user: weblogic/brh not found!;exit 1"

bea_path="/home/${user_id}/bea"
bsu_path="${bea_path}/utils/bsu"

test -d ${bsu_path} ||\
eval "echo path: ${bsu_path}  not found!;exit 1"

cache_path="${bsu_path}/cache_dir"
test -d ${cache_path} ||\
mkdir -p ${cache_path}
test -d ${cache_path} &&\
chown ${user_id}.${user_id} ${cache_path}

url="http://${yum_server}/patch/weblogic/CVE-2017-10271p26519424_1036_Generic.zip"
package=`echo ${url}|awk -F'/' '{print $NF}'`
wget ${url} -O ${cache_path}/${package}

test -f ${cache_path}/${package} &&\
chown ${user_id}.${user_id} ${cache_path}/${package} ||\
eval "echo ${cache_path}/${package} not found!;exit 1"

test -f ${cache_path}/${package} &&\
cd ${cache_path} &&\
unzip -nq ${package}

test -f ${cache_path}/FMJJ.jar ||\
eval "${cache_path}/FMJJ.jar not found!;exit 1"

prod_dir="${bea_path}/wlserver_10.3"
test -d "${prod_dir}" ||\
eval "echo path: ${prod_dir} not found!;exit 1"

echo "./bsu.sh -remove -patchlist=ZLNA -prod_dir=${prod_dir} -log=/tmp/remove.log
./bsu.sh -remove -patchlist=EJUW -prod_dir=${prod_dir} -log=/tmp/remove.log
./bsu.sh -install -patch_download_dir=${cache_path} -patchlist=FMJJ -prod_dir=${prod_dir} -verbose" > ${bsu_path}/update_weblogic.sh

test -f ${bsu_path}/update_weblogic.sh &&\
chmod +x ${bsu_path}/update_weblogic.sh &&\
chown ${user_id}.${user_id} ${bsu_path}/update_weblogic.sh

timestamps=`date -d now +"%F-%T"|sed 's/:/_/g'`
test -f ${bsu_path}/bsu.sh &&\
sed -r -i.bak.${timestamps} 's/^MEM_ARGS.*/MEM_ARGS=\"-Xms1G -Xmx2G\"/' ${bsu_path}/bsu.sh ||\
eval "echo ${bsu_path}/bsu.sh not found!;exit 1"

su - "${user_id}" -c "cd ${bsu_path} && nohup ./update_weblogic.sh > /tmp/update_weblogic.log &"
