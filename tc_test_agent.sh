#!/bin/bash

# system updating
sudo apt update
sudo apt upgrade -y

# JDK installation
sudo apt install openjdk-8-jdk -y
sudo apt install unzip
echo JAVA_HOME=\"/usr/lib/jvm/java-8-openjdk-amd64\" >> /etc/environment
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# downloading and configuring CI/CD agent
sudo mkdir /TC_ci-cd
cd /TC_ci-cd
sudo wget http://${CI_CD_IP}:8111/update/buildAgent.zip
sudo unzip buildAgent.zip -d buildAgent
cd buildAgent
sudo cp conf/buildAgent.dist.properties conf/buildAgent.properties
sudo rm conf/buildAgent.dist.properties
sudo sed -i 's/localhost/'${CI_CD_IP}'/g' conf/buildAgent.properties
sudo sed -i 's/name=/name='${AGENT_NAME}'/g' conf/buildAgent.properties

# waiting before CI/CD server start
sleep 5

# starting agent
sudo buildAgent/bin/./agent.sh start

# adding agent service to auto-reload services
sudo echo "#!"/bin"/bash""" > tmp123
sudo echo "sudo /TC_ci-cd/buildAgent/bin/./agent.sh start" >> tmp123
sudo cat tmp123 > /etc/rc.local
sudo rm -r tmp123
sudo chmod +x /etc/rc.local