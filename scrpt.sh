#!/bin/bash

echo 'system update'
sudo apt update
sudo apt upgrade -y

echo 'adding repos to source list'
sudo rm -rf /etc/apt/sources.list.d/mysql.list
sudo echo 'deb http://repo.mysql.com/apt/ubuntu/ bionic mysql-apt-config' >> /etc/apt/sources.list.d/mysql.list
sudo echo 'deb http://repo.mysql.com/apt/ubuntu/ bionic mysql-5.7' >> /etc/apt/sources.list.d/mysql.list
sudo echo 'deb http://repo.mysql.com/apt/ubuntu/ bionic mysql-tools' >> /etc/apt/sources.list.d/mysql.list
sudo echo 'deb-src http://repo.mysql.com/apt/ubuntu/ bionic mysql-5.7' >> /etc/apt/sources.list.d/mysql.list

echo 'adding key'
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 8C718D3B5072E1F5

sudo apt update
sudo apt upgrade -y

echo 'installing mysql-client'
sudo apt install -f -y mysql-client=5.7.35-1ubuntu18.04 > /dev/null 2>&1
#echo 'installing mysql-community-server'
#sudo apt install -f -y mysql-community-server=5.7.35-1ubuntu18.04 > /dev/null 2>&1
echo 'installing mysql-server'
sudo apt install -f -y mysql-server=5.7.35-1ubuntu18.04 > /dev/null 2>&1
echo 'mysql installed'

echo 'creating DATABASE'
echo 'CREATE DATABASE eschool;' > db_creating.tmp
sudo mysql < db_creating.tmp

echo 'creating USER'
echo 'CREATE USER '\''spark'\''@'\''%'\'' IDENTIFIED BY '\''Qwerty12345'\'';' > user_creating.tmp
sudo mysql < user_creating.tmp

echo 'granting PRIVILEGES'
echo 'GRANT ALL PRIVILEGES ON *.* TO '\''spark'\''@'\''%'\'';' > db_prev.tmp
sudo mysql < db_prev.tmp

sudo rm db_prev.tmp
sudo rm db_creating.tmp
sudo rm user_creating.tmp

sudo echo 'DATABASE configuration - done'

sudo echo 'mysqld.cnf configuration'
sudo sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo echo 'done'

sudo echo 'restart mysql'
sudo systemctl restart mysql
sudo echo 'done'
