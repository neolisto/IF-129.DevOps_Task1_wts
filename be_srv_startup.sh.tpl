#!/bin/bash

# system updating
sudo apt update
sudo apt upgrade -y

# exporting user data for Java-application
export DATASOURCE_USERNAME=${DATASOURCE_USERNAME}
export DATASOURCE_PASSWORD=${DATASOURCE_PASSWORD}

# installing OpenJDK v.8
sudo apt install openjdk-8-jdk -y

# installing maven
sudo apt install maven -y

# downloading eSchool project
sudo mkdir /application
cd /application
git clone https://github.com/yurkovskiy/eSchool.git

# work-directory changing
cd eSchool/

# commenting non-usable test
sudo echo '/**' >src/test/java/academy/softserve/eschool/controller/ScheduleControllerIntegrationTest.java
sudo echo '**/' >>src/test/java/academy/softserve/eschool/controller/ScheduleControllerIntegrationTest.java

# changing default DB-server IP to real
sudo sed -i 's/localhost/'${DB_SRV_IP}'/g' src/main/resources/application.properties

# changing default DB-server user to real
sudo sed -i '3s/.*/spring.datasource.username=\'${DATASOURCE_USERNAME}'/' src/main/resources/application.properties
sudo sed -i '4s/.*/spring.datasource.password=\'${DATASOURCE_PASSWORD}'/' src/main/resources/application.properties

#  maven build start
sudo mvn clean

# maven packg build start
sudo mvn package

# auto loading after reboot
sudo echo "#!"/bin"/bash""" > tmp123
sudo echo "sudo nohup java -jar /application/eSchool/target/eschool.jar &" >> tmp123
sudo cat tmp123 > /etc/rc.local
sudo rm -r tmp123
sudo chmod +x /etc/rc.local

# java-app start
cd target/
sudo nohup java -jar eschool.jar &
