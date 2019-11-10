#!/usr/bin/env bash

echo "Content-type: text/html"
echo ""

source /etc/profile

export PRESTO_NODE_ID=`curl -s http://169.254.169.254/latest/meta-data/instance-id`

mkdir -p /tmp/presto-config-template
aws s3 sync $PRESTO_CONFIG_PATH /tmp/presto-config-template

cd /tmp/presto-config-template

files=`find . -type f`
for f in $files
do
    mkdir -p $PRESTO_HOME/etc/`dirname $f`
    envsubst < $f | tee $PRESTO_HOME/etc/$f > /dev/null
done

sudo /usr/bin/restart-presto
