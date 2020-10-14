#!/usr/bin/env bash

set -e

export PRESTO_VERSION=340
export PRESTO_DATOMIC_VERSION=0.9.6045

sudo amazon-linux-extras install java-openjdk11
sudo yum install -y httpd

wget https://repo1.maven.org/maven2/io/prestosql/presto-server/$PRESTO_VERSION/presto-server-$PRESTO_VERSION.tar.gz
wget https://downloads.alluxio.io/downloads/files/2.3.0/alluxio-2.3.0-bin.tar.gz

sudo tar -xvf /home/ec2-user/presto-*.tar.gz -C /usr/lib
sudo tar -xvf /home/ec2-user/alluxio-*.tar.gz -C /usr/lib

echo "export JAVA_HOME=$(echo /usr/lib/jvm/jre)" | sudo tee -a /etc/profile > /dev/null
echo "export PRESTO_HOME=$(echo /usr/lib/presto*)" | sudo tee -a /etc/profile > /dev/null
echo "export ALLUXIO_HOME=$(echo /usr/lib/alluxio*)" | sudo tee -a /etc/profile > /dev/null
echo "export PATH=$PATH:$(echo /usr/lib/apache-hive*/bin)" | sudo tee -a /etc/profile > /dev/null

source /etc/profile

sudo chown root $PRESTO_HOME
sudo chgrp root $PRESTO_HOME
sudo chown root $ALLUXIO_HOME
sudo chgrp root $ALLUXIO_HOME

mkdir -p ~/presto

sudo mkdir -p $PRESTO_HOME/etc/datomic-dbs
sudo chmod -R 0777 $PRESTO_HOME/etc

sudo cp $ALLUXIO_HOME/client/*.jar $PRESTO_HOME/lib

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
