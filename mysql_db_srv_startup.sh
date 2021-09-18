#!/bin/bash

#system repository updating
echo 'system update'
sudo apt update
sudo apt upgrade -y

#adding mysql v. 5.7 to apt installation repository
echo 'adding repos to source list'
sudo echo 'deb http://repo.mysql.com/apt/ubuntu/ bionic mysql-apt-config' >> /etc/apt/sources.list.d/mysql.list
sudo echo 'deb http://repo.mysql.com/apt/ubuntu/ bionic mysql-5.7' >> /etc/apt/sources.list.d/mysql.list
sudo echo 'deb http://repo.mysql.com/apt/ubuntu/ bionic mysql-tools' >> /etc/apt/sources.list.d/mysql.list
sudo echo 'deb-src http://repo.mysql.com/apt/ubuntu/ bionic mysql-5.7' >> /etc/apt/sources.list.d/mysql.list

#adding install-key for legacy version
echo 'adding key'
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 8C718D3B5072E1F5

#updating system with new source repository
sudo apt update
sudo apt upgrade -y

#installation of mysql client
echo 'installing mysql-client'
sudo apt install -f -y mysql-client=5.7.35-1ubuntu18.04

#installation of mysql server
echo 'installing mysql-server'
sudo DEBIAN_FRONTEND=noninteractive apt install -y mysql-server=5.7.35-1ubuntu18.04
echo 'mysql installed'

#creating database
echo 'creating DATABASE'
echo 'CREATE DATABASE eschool;' > db_creating.tmp
sudo mysql < db_creating.tmp

#creating user
echo 'creating USER'
echo 'CREATE USER '\'$DATASOURCE_USERNAME\''@'\''%'\'' IDENTIFIED BY '\'$DATASOURCE_PASSWORD\'';' > user_creating.tmp
sudo mysql < user_creating.tmp

#granting privileges to user
echo 'granting PRIVILEGES'
echo 'GRANT ALL PRIVILEGES ON *.* TO '\'$DATASOURCE_USERNAME\''@'\''%'\'';' > db_prev.tmp
sudo mysql < db_prev.tmp

#removing temporary files
sudo rm db_prev.tmp
sudo rm db_creating.tmp
sudo rm user_creating.tmp

sudo echo 'DATABASE configuration - done'

#open mysql server for remote connection
sudo echo 'mysqld.cnf configuration'
sudo sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo echo 'done'

#restarting mysql service with new parameters
sudo systemctl enable mysql
sudo echo 'restart mysql'
sudo systemctl restart mysql
sudo echo 'done'

# CI/CD agent installation
sudo apt install openjdk-8-jdk -y
sudo apt install unzip
echo JAVA_HOME=\"/usr/lib/jvm/java-8-openjdk-amd64\" >> /etc/environment
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# waiting before CI/CD server start
sleep 10m

# downloading and configuring CI/CD agent
sudo mkdir /TC_ci-cd
cd /TC_ci-cd
sudo wget http://$CI_CD_IP:8111/update/buildAgent.zip
sudo unzip buildAgent.zip -d buildAgent
cd buildAgent
sudo cp conf/buildAgent.dist.properties conf/buildAgent.properties
sudo rm conf/buildAgent.dist.properties
sudo sed -i 's/localhost/'$CI_CD_IP'/g' conf/buildAgent.properties
sudo sed -i 's/name=/name='$AGENT_NAME'/g' conf/buildAgent.properties

# starting agent
sudo bin/./agent.sh start

# adding agent service to auto-reload services
sudo echo "#!"/bin"/bash""" > tmp123
sudo echo "sudo /TC_ci-cd/buildAgent/bin/./agent.sh start" >> tmp123
sudo cat tmp123 >> /etc/rc.local
sudo rm -r tmp123
sudo chmod +x /etc/rc.local
