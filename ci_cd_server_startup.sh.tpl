#!/bin/bash

sudo apt update
sudo apt upgrade -y
sudo apt install openjdk-8-jdk -y
sudo mkdir /TC_ci-cd
cd /TC_ci-cd

echo JAVA_HOME=\"/usr/lib/jvm/java-8-openjdk-amd64\" >> /etc/environment
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
wget https://download-cdn.jetbrains.com/teamcity/TeamCity-2021.1.3.tar.gz
sudo tar xfv TeamCity-2021.1.3.tar.gz
sudo rm TeamCity-2021.1.3.tar.gz
sudo TeamCity/bin/./teamcity-server.sh start
sudo echo "#!"/bin"/bash""" > tmp123
sudo echo "sudo /TeamCity/bin/./teamcity-server.sh start" >> tmp123
sudo cat tmp123 > /etc/rc.local
sudo rm -r tmp123
sudo chmod +x /etc/rc.local
sleep 5m
cat /TeamCity/logs/teamcity-server.log | grep token > /home/TeamCity/adm_token.txt