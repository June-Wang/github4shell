#!/bin/bash

test -f ./jdk-8u231-linux-x64.rpm &&\
rpm -ivh jdk-8u231-linux-x64.rpm

jdk_path='/usr/java/jdk1.8.0_231-amd64'

test -f /etc/profile.d/jdk_env.sh ||\
echo "export JAVA_HOME=${jdk_path}
export JAVA_BIN=${jdk_path}/bin
export PATH=\$PATH:\$JAVA_HOME/bin
export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar
export JAVA_HOME JAVA_BIN PATH CLASSPATH" > /etc/profile.d/jdk_env.sh

