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
echo "upstream backend {" > /etc/nginx/conf.d/load-balancing.conf
echo "ip_hash;" >> /etc/nginx/conf.d/load-balancing.conf
echo "server BE1_SRV_IP:8080;" >> /etc/nginx/conf.d/load-balancing.conf
echo "server BE2_SRV_IP:8080;" >> /etc/nginx/conf.d/load-balancing.conf
echo "}" >> /etc/nginx/conf.d/load-balancing.conf
echo "server {" >> /etc/nginx/conf.d/load-balancing.conf
echo "listen 80;" >> /etc/nginx/conf.d/load-balancing.conf
echo "server_name loadbalancing.example.com;" >> /etc/nginx/conf.d/load-balancing.conf
echo "location / {" >> /etc/nginx/conf.d/load-balancing.conf
echo "proxy_redirect off;" >> /etc/nginx/conf.d/load-balancing.conf
echo "proxy_set_header X-Real-IP \$remote_addr;" >> /etc/nginx/conf.d/load-balancing.conf
echo "proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;" >> /etc/nginx/conf.d/load-balancing.conf
echo "proxy_set_header    Host \$http_host;" >> /etc/nginx/conf.d/load-balancing.conf
echo "proxy_pass http://backend;" >> /etc/nginx/conf.d/load-balancing.conf
echo "}" >> /etc/nginx/conf.d/load-balancing.conf
echo "}" >> /etc/nginx/conf.d/load-balancing.conf

# adding real IP-addresses of BE-servers
sudo sed -i 's/BE1_SRV_IP/'$BE1_SRV_IP'/g' /etc/nginx/conf.d/load-balancing.conf
sudo sed -i 's/BE2_SRV_IP/'$BE2_SRV_IP'/g' /etc/nginx/conf.d/load-balancing.conf

# configuration test of nginx .conf files
sudo nginx -t

# restarting nginx service
sudo systemctl restart nginx
