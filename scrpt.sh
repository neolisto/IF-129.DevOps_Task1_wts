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
echo 'CREATE USER '\'${DATASOURCE_USERNAME}\''@'\''%'\'' IDENTIFIED BY '\'${DATASOURCE_PASSWORD}\'';' > user_creating.tmp
sudo mysql < user_creating.tmp

#granting privileges to user
echo 'granting PRIVILEGES'
echo 'GRANT ALL PRIVILEGES ON *.* TO '\'${DATASOURCE_USERNAME}\''@'\''%'\'';' > db_prev.tmp
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
sudo echo 'restart mysql'
sudo systemctl restart mysql
sudo echo 'done'
