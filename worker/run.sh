#!/usr/bin/env bash

set -e

sudo mkfs -t xfs /dev/sdb
sudo mkdir /data
sudo mount /dev/sdb /data
sudo mkdir /data/s3staging
sudo mkdir /data/spill
sudo chown -R ec2-user /data
sudo chgrp -R ec2-user /data

export ENV=$1
export PRESTO_CONFIG_PATH=$2

cd `dirname $0`

SYSTEM_MEMORY_KB=$(cat /proc/meminfo | grep MemTotal | grep -oe '[0-9]*')
JVM_MEM=$((($SYSTEM_MEMORY_KB / 5) * 4))K # Everything minus 4gb

echo "export PRESTO_CONFIG_PATH=$PRESTO_CONFIG_PATH" | sudo tee -a /etc/profile > /dev/null
echo "export ENV=$ENV" | sudo tee -a /etc/profile > /dev/null
echo "export JVM_XMX=$JVM_MEM" | sudo tee -a /etc/profile > /dev/null
echo "export JVM_XMS=$JVM_MEM" | sudo tee -a /etc/profile > /dev/null

source /etc/profile

sudo systemctl start httpd
sudo cp update-config.sh /var/www/cgi-bin/update-config.sh
sudo chmod +x /var/www/cgi-bin/update-config.sh

/var/www/cgi-bin/update-config.sh
sudo chmod -R 0777 $PRESTO_HOME/etc
