#!/bin/bash
# endpoint(Ex : megazone-hands-on-rds.c6gradmwj7dj.ap-northeast-2.rds.amazonaws.com)
rds_endpoint='megazone-hands-on-rds.c6gradmwj7dj.ap-northeast-2.rds.amazonaws.com'
# Please enter your master username(Ex : username )
rds_username='username'
# Please enter your rds user password(Ex : password)
rds_password='Root123!'
# Please enter your memcache endpoint(Ex : megazone-hands-on.ndzwq5.cfg.apn2.cache.amazonaws.com:11211)
memcache_endpoint='megazone-hands-on.ndzwq5.cfg.apn2.cache.amazonaws.com:11211'
# Please enter your Amazon S3 bucket nname(Ex : megazone-hands-on-syha)
s3_bucket_name='megazone-hands-on-syha'

function RDS_memcache_setting(){
  ## RDS, memcache 설정 전 파일 백업
  echo $rds_endpoint $rds_username $rds_password $memcache_endpoint
  sudo cp -rp /var/www/html/web-demo/config.php /var/www/html/web-demo/config.php.$day

  ## RDS 설정
  RDS_check_con=$(nc -z -w5 $rds_endpoint 3306 | grep "succeeded")
  if  [ -n "$RDS_check_con" ];then  ## DB dump insert
    mysql -h $rds_endpoint -u $rds_username -p''$rds_password'' web_demo < /var/www/html/web-demo/web_demo.sql  >& /dev/null
    rds_check=$(mysql -h $rds_endpoint -u $rds_username -p''$rds_password'' web_demo -e "select * from upload_images" | wc -l)
    sudo perl -pi -e "s/$db_hostname = \"localhost\"\;/$db_hostname = \"$rds_endpoint\"\;/g" /var/www/html/web-demo/config.php
    sudo perl -pi -e "s/$db_username = \"username\"\;/$db_username = \"$rds_username\"\;/g" /var/www/html/web-demo/config.php
    sudo perl -pi -e "s/$db_password = \"password\"\;/$db_password = \"$rds_password\"\;/g" /var/www/html/web-demo/config.php
    echo "RDS setup is completed."
  else
    echo "Can not access RDS endpoint"
  fi

  ## memcache 설정
  memcache=$(echo  $memcache_endpoint | awk -F":" '{print $1}')  ## port number 분리
  memcache_check_con=$(nc -z -w5 $memcache 11211 | grep "succeeded" )  ## memcache 접근 체크
  if  [ -n "$memcache_check_con" ];then  ## php.ini 변경
        sudo cp -rp /etc/php.ini /etc/php.ini.$day ## backup
        sudo perl -pi -e "s/session.save_handler = files/session.save_handler = memcache/g" /etc/php.ini
        sudo perl -pi -e "s/session.save_path = \"\/var\/lib\/php\/session\"/session.save_path = $memcache_endpoint/g" /etc/php.ini
        sudo perl -pi -e "s/;date.timezone =/date.timezone = America\/New_York/g" /etc/php.ini
        echo "memcache setup is completed."
  else
    echo "Can not access memcache endpoint"
  fi
}

function s3_config(){
  sudo perl -pi -e "s/$storage_option = \"hd\"\;/$storage_option = \"s3\"\;/g" /var/www/html/web-demo/config.php
  sudo perl -pi -e "s/$s3_bucket  = \"my-upload-bucket\"\;/$s3_bucket  = \"$s3_bucket_name\";/g" /var/www/html/web-demo/config.php

  # AWS CLI upgrade
  sudo pip install awscli --upgrade --user
  # Amazon S3 public access settings
  sudo aws s3api put-public-access-block --bucket $s3_bucket_name --public-access-block-configuration BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false
  # Upload public images
  sudo aws s3 sync --acl public-read /var/www/html/web-demo/uploads/ s3://$s3_bucket_name >& /dev/null
}

## 필수 패키지 설치
sudo yum update -y  >& /dev/null
sudo yum install -y httpd php-5.3.29 php-mysql-5.3.29 mysql-server-5.5 telnet git curl php-pecl-memcache >& /dev/null
sudo yum update -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm >& /dev/null

# Define PHP date timezone
sudo perl -pi -e "s/\;date.timezone =/date.timezone = Asia\/Seoul/g" /etc/php.ini

## source downloads
sudo chown -R ec2-user:ec2-user /var/www
cd /var/www/html
sudo git clone https://github.com/blueice123/megazone-hands-on-lab.git  >& /dev/null
sudo mv /var/www/html/megazone-hands-on-lab /var/www/html/web-demo >& /dev/null

#AWS memcached & Amazon RDS setting
RDS_memcache_setting
## Amazon S3 setting
s3_config $s3_bucket_name

## Apache 시작
sudo service httpd start >& /dev/null
sudo chkconfig httpd on
