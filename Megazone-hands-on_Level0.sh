#!/bin/bash

## Install package
sudo yum update -y  >& /dev/null
sudo yum install -y httpd php-5.3.29 php-mysql-5.3.29 mysql-server-5.5 telnet git curl  >& /dev/null
sudo yum update -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm >& /dev/null

# Define PHP date timezone
sudo perl -pi -e "s/\;date.timezone =/date.timezone = Asia\/Seoul/g" /etc/php.ini

## Download source files
sudo chown -R ec2-user:ec2-user /var/www
cd /var/www/html
sudo git clone https://github.com/blueice123/megazone-hands-on-lab.git  >& /dev/null
sudo mv /var/www/html/megazone-hands-on-lab /var/www/html/web-demo >& /dev/null
sudo chown -R apache:apache /var/www/html/web-demo/uploads

## Start service(Apache, MySQL)
sudo service mysqld start >& /dev/null
sudo service httpd start >& /dev/null
sudo chkconfig httpd on

## Setting Database and insert dump
echo -e "\nPlease press Enter key"
mysql -u root -p'' mysql -e "CREATE DATABASE web_demo" >& /dev/null
echo -e "\nPlease press Enter key"
mysql -u root -p'' mysql -e "CREATE USER 'username'@'%' IDENTIFIED BY 'password'"  >& /dev/null
echo -e "\nPlease press Enter key"
mysql -u root -p'' mysql -e "GRANT ALL on web_demo.* to username@'localhost' IDENTIFIED BY 'password' with grant option" >& /dev/null
mysql -u username -p'password' web_demo < /var/www/html/web-demo/web_demo.sql  >& /dev/null
mysql -u username -p'password' web_demo -e "select * from upload_images"

## Restart apache service
sudo service httpd restart >& /dev/null

## Ec2 public ip check
Publicip=$(curl http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)
echo "URL : http://"$Publicip"/web-demo"
