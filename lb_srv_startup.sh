#!/bin/bash

# system update
sudo apt update
sudo apt upgrade -y

# installing nginx
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx

# editing nginx-server config files
sudo rm -rf /etc/nginx/sites-enabled/default
sudo rm /etc/nginx/conf.d/load-balancing.conf
sudo cp load-balancing.conf /etc/nginx/conf.d/load-balancing.conf
sudo rm load-balancing.conf

# adding real IP-adresses of BE-servers
sudo sed -i 's/BE1_SRV_IP/'$BE1_SRV_IP'/g' /etc/nginx/conf.d/load-balancing.conf
sudo sed -i 's/BE2_SRV_IP/'$BE2_SRV_IP'/g' /etc/nginx/conf.d/load-balancing.conf

# configuration test of nginx .conf files
sudo nginx -t

# restarting nginx service
sudo systemctl restart nginx
