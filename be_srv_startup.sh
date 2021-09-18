#!/bin/bash

# system updating
sudo apt update
sudo apt upgrade -y

export DATASOURCE_USERNAME=some_value
export DATASOURCE_PASSWORD=some_value

# installing OpenJDK v.8
sudo apt install openjdk-8-jdk -y

# installing maven
sudo apt install maven -y

# downloading eSchool project
mkdir /application
cd /application
git clone https://github.com/yurkovskiy/eSchool.git

# work-directory changing
cd eSchool/

# commenting non-usable test
sudo echo '/**' >src/test/java/academy/softserve/eschool/controller/ScheduleControllerIntegrationTest.java
sudo echo '**/' >>src/test/java/academy/softserve/eschool/controller/ScheduleControllerIntegrationTest.java

# changing default DB-server IP to real
sudo sed -i 's/localhost/'$DB_SRV_IP'/g' src/main/resources/application.properties

# changing default DB-server user to real
sudo sed -i '3s/.*/spring.datasource.username=\'$DATASOURCE_USERNAME'/' src/main/resources/application.properties
sudo sed -i '4s/.*/spring.datasource.password=\'$DATASOURCE_PASSWORD'/' src/main/resources/application.properties

#  maven build start
sudo mvn clean

# maven packg build start
sudo mvn package

# auto loading after reboot
sudo echo "#!"/bin"/bash""" > tmp123
sudo echo "sudo nohup java -jar /application/eSchool/target/eschool.jar &" >> tmp123
sudo echo "sudo /TC_ci-cd/buildAgent/bin/./agent.sh start" >> tmp123
sudo cat tmp123 > /etc/rc.local
sudo rm -r tmp123
sudo chmod +x /etc/rc.local

# java-app start
cd target/
sudo nohup java -jar eschool.jar &

# CI/CD agent installation
sudo apt install unzip
echo JAVA_HOME=\"/usr/lib/jvm/java-8-openjdk-amd64\" >> /etc/environment
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# waiting before CI/CD server start
sleep 5m

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