#!/bin/bash

# system updating
sudo apt update
sudo apt upgrade -y

# JDK installation
sudo apt install openjdk-8-jdk -y
echo JAVA_HOME=\"/usr/lib/jvm/java-8-openjdk-amd64\" >> /etc/environment
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# downloading and configuring CI/CD server (TeamCity)
sudo mkdir /TC_ci-cd
cd /TC_ci-cd
wget https://download-cdn.jetbrains.com/teamcity/TeamCity-2021.1.3.tar.gz
sudo tar xfv TeamCity-2021.1.3.tar.gz
sudo rm TeamCity-2021.1.3.tar.gz

# server start
sudo TeamCity/bin/./teamcity-server.sh start

# adding server to auto-reload services
sudo echo "#!"/bin"/bash""" > tmp123
sudo echo "sudo /TeamCity/bin/./teamcity-server.sh start" >> tmp123
sudo cat tmp123 > /etc/rc.local
sudo rm -r tmp123
sudo chmod +x /etc/rc.local

# waiting before server start and copy root-token to static file
sleep 5m
sudo cp /TC_ci-cd/TeamCity/logs/teamcity-server.log /TC_ci-cd/adm_token.txt