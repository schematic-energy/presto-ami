#!/usr/bin/env bash

set -e

sudo mkdir /data
sudo mkdir /data/s3staging
sudo mkdir /data/spill
sudo chown -R ec2-user /data
sudo chgrp -R ec2-user /data

set -e

export ENV=$1
export PRESTO_CONFIG_PATH=$2

cd `dirname $0`

SYSTEM_MEMORY_KB=$(cat /proc/meminfo | grep MemTotal | grep -oe '[0-9]*')
JVM_MEM=$((($SYSTEM_MEMORY_KB / 5) * 4))K # 80% of system memory

echo "export PRESTO_CONFIG_PATH=$PRESTO_CONFIG_PATH" | sudo tee -a /etc/profile > /dev/null
echo "export ENV=$ENV" | sudo tee -a /etc/profile > /dev/null
echo "export JVM_XMX=$JVM_MEM" | sudo tee -a /etc/profile > /dev/null
echo "export JVM_XMS=$JVM_MEM" | sudo tee -a /etc/profile > /dev/null

source /etc/profile

export AWS_REGION=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/.$//'`

get_ssm () {
    echo $(aws ssm get-parameter \
          --name $1 \
          --region $AWS_REGION \
          --output text --query 'Parameter.Value' \
          --with-decryption )
}

export HIVE_METASTORE_HOST=`get_ssm /scio/$ENV/hive-metastore/host`
export HIVE_METASTORE_PORT=5432
export HIVE_METASTORE_DB=hive
export HIVE_METASTORE_USER=hive
export HIVE_METASTORE_PASSWORD=`get_ssm /scio/$ENV/hive-metastore/password`
export HIVE_METASTORE_JDBC_URL=jdbc:postgresql://$HIVE_METASTORE_HOST:$HIVE_METASTORE_PORT/$HIVE_METASTORE_DB
export HADOOP_CLASSPATH=$HADOOP_CLASSPATH:$HADOOP_HOME/share/hadoop/tools/lib/*

sudo cp core-site.xml $HADOOP_HOME/etc/core-site.xml
envsubst < hive-site.xml.template | sudo tee $HIVE_HOME/conf/hive-site.xml > /dev/null

$HIVE_HOME/bin/schematool -dbType postgres -initSchema || $HIVE_HOME/bin/schematool -dbType postgres -upgradeSchema

PATH=$PATH:$HIVE_HOME/bin

nohup hive --service metastore &> metastore.out &

nohup hive --service hiveserver2 &> hiveserver2.out &

sudo systemctl start httpd
sudo cp update-config.sh /var/www/cgi-bin/update-config.sh
sudo cp healthcheck.sh /var/www/cgi-bin/healthcheck.sh
sudo chmod +x /var/www/cgi-bin/update-config.sh
sudo chmod +x /var/www/cgi-bin/healthcheck.sh

/var/www/cgi-bin/update-config.sh
sudo chmod -R 0777 $PRESTO_HOME/etc
