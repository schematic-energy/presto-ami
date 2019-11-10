#!/usr/bin/env bash

sudo yum install -y java-1.8.0-openjdk.x86_64
sudo yum install -y httpd

wget https://repo1.maven.org/maven2/io/prestosql/presto-server/323/presto-server-323.tar.gz

sudo tar -xvf /home/ec2-user/presto-*.tar.gz -C /usr/lib

echo "export JAVA_HOME=$(echo /usr/lib/jvm/jre)" | sudo tee -a /etc/profile > /dev/null
echo "export PRESTO_HOME=$(echo /usr/lib/presto*)" | sudo tee -a /etc/profile > /dev/null
echo "export PATH=$PATH:$(echo /usr/lib/apache-hive*/bin)" | sudo tee -a /etc/profile > /dev/null

source /etc/profile

sudo chown root $PRESTO_HOME
sudo chgrp root $PRESTO_HOME

mkdir -p ~/presto

sudo mkdir $PRESTO_HOME/etc
sudo chmod -R 0777 $PRESTO_HOME/etc

echo "$PRESTO_HOME/bin/launcher restart" | sudo tee -a /usr/bin/restart-presto > /dev/null
sudo chmod +x /usr/bin/restart-presto

echo "apache        ALL=(ALL)       NOPASSWD: /usr/bin/restart-presto" | sudo tee -a /etc/sudoers.d/apache > /dev/null
