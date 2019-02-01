#!/bin/bash

sudo perl -pi -e "s/$latency = 0\;/$latency = 5\;/g" /var/www/html/web-demo/config.php
sudo service httpd restart >& /dev/null
