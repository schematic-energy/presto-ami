#!/usr/bin/env bash

export PRESTO_VERSION=330
export PRESTO_DATOMIC_VERSION=0.9.6045

sudo yum install -qy java-1.8.0-openjdk.x86_64
sudo yum install -y httpd

wget http://mirrors.gigenet.com/apache/hadoop/common/hadoop-2.9.2/hadoop-2.9.2.tar.gz
wget http://mirrors.gigenet.com/apache/hive/hive-2.3.6/apache-hive-2.3.6-bin.tar.gz
wget https://repo1.maven.org/maven2/io/prestosql/presto-server/$PRESTO_VERSION/presto-server-$PRESTO_VERSION.tar.gz

sudo tar -xvf /home/ec2-user/hadoop*.tar.gz -C /usr/lib
sudo tar -xvf /home/ec2-user/apache-hive*.tar.gz -C /usr/lib
sudo tar -xvf /home/ec2-user/presto-*.tar.gz -C /usr/lib

echo "export JAVA_HOME=$(echo /usr/lib/jvm/jre)" | sudo tee -a /etc/profile > /dev/null
echo "export HADOOP_HOME=$(echo /usr/lib/hadoop*)" | sudo tee -a /etc/profile > /dev/null
echo "export HIVE_HOME=$(echo /usr/lib/apache-hive*)" | sudo tee -a /etc/profile > /dev/null
echo "export PRESTO_HOME=$(echo /usr/lib/presto*)" | sudo tee -a /etc/profile > /dev/null
echo "export PATH=$PATH:$(echo /usr/lib/apache-hive*/bin)" | sudo tee -a /etc/profile > /dev/null

source /etc/profile

sudo chown root $HADOOP_HOME
sudo chgrp root $HADOOP_HOME
sudo chown root $HIVE_HOME
sudo chgrp root $HIVE_HOME
sudo chown root $PRESTO_HOME
sudo chgrp root $PRESTO_HOME

sudo mkdir $HADOOP_HOME/logs
sudo chmod 777 $HADOOP_HOME/logs

mkdir -p ~/hive
mkdir -p ~/presto

sudo mkdir -p $PRESTO_HOME/etc/datomic-dbs
sudo chmod -R 0777 $PRESTO_HOME/etc

echo "$PRESTO_HOME/bin/launcher restart" | sudo tee -a /usr/bin/restart-presto > /dev/null
sudo chmod +x /usr/bin/restart-presto

echo "apache        ALL=(ALL)       NOPASSWD: /usr/bin/restart-presto" | sudo tee -a /etc/sudoers.d/apache > /dev/null

if [ -z "$PRESTO_DATOMIC_USER" ]
then
    echo "Datomic version not specified, skipping"
else
    wget --http-user=$PRESTO_DATOMIC_USER --http-password=$PRESTO_DATOMIC_PASSWORD https://my.datomic.com/repo/com/datomic/datomic-pro/$PRESTO_DATOMIC_VERSION/datomic-pro-$PRESTO_DATOMIC_VERSION.zip -O datomic.zip

    sudo cp /home/ec2-user/peer-server /usr/bin/peer-server
    sudo chmod +x /usr/bin/peer-server

    sudo cp /home/ec2-user/peer-server.service /etc/systemd/system/peer-server.service

    sudo unzip ~/datomic.zip -d /usr/lib
    echo "export DATOMIC_HOME=$(echo /usr/lib/datomic*)" | sudo tee -a /etc/profile > /dev/null
    source /etc/profile
    sudo cp -r $DATOMIC_HOME/presto-server/plugin/datomic $PRESTO_HOME/plugin/datomic
    echo "systemctl restart peer-server.service" | sudo tee -a /usr/bin/restart-presto > /dev/null
fi
