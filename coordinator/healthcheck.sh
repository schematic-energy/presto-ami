#!/usr/bin/env bash

presto=`ps aux | grep presto-server | grep java | awk '{print $2}'`
metastore=`ps aux | grep hive-metastore | grep java | awk '{print $2}'`
hive=`ps aux | grep hive-service | grep java | awk '{print $2}'`

if [ -z "$presto" ]
then
    echo "Status: 500 Internal Server Error"
    echo "Content-type: text/html"
    echo ""
    echo "Presto process not running"
    exit 1
fi

if [ -z "$metastore" ]
then
    echo "Status: 500 Internal Server Error"
    echo "Content-type: text/html"
    echo ""
    echo "Hive Metastore process not running"
    exit 1
fi

if [ -z "$hive" ]
then
    echo "Status: 500 Internal Server Error"
    echo "Content-type: text/html"
    echo ""
    echo "Hive Server process not running"
fi

echo "Status: 200 OK"
echo "Content-type: text/html"
echo ""
echo "Presto PID is $presto <br>"
echo "Hive Metastore PID is $metastore <br>"
echo "Hive Service PID is $hive <br>"

exit 0
