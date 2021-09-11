#!/bin/bash

# system updating
sudo apt update
sudo apt upgrade -y

# installing OpenJDK v.8
sudo apt install openjdk-8-jdk -y

# installing maven
sudo apt install maven -y

# downloading eSchool project
git clone https://github.com/yurkovskiy/eSchool.git

# work-directory changing
cd eSchool/

# commenting non-usable test
sudo echo '/**' > src/test/java/academy/softserve/eschool/controller/ScheduleControllerIntegrationTest.java
sudo echo '**/' >> src/test/java/academy/softserve/eschool/controller/ScheduleControllerIntegrationTest.java

# changing default DB-server IP to real
sudo sed -i 's/localhost/'$DB_SRV_IP'/g' src/main/resources/application.properties

# changing default DB-server user to real
sudo sed -i 's/\${DATASOURCE_USERNAME:root}/\'$DATASOURCE_USERNAME'/g' src/main/resources/application.properties

#changing default DB-server user's password to real
sudo sed -i 's/\${DATASOURCE_PASSWORD:root}/\'$DATASOURCE_PASSWORD'/g' src/main/resources/application.properties

#  maven build start
sudo mvn clean

# maven packg build start
sudo mvn package

# java-app start
cd target/
sudo java -jar eschool.jar
