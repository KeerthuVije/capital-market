#!/bin/bash

## COMMON
# update yum packages and install httpd server
sudo yum update -y
sudo yum install httpd -y

## EMAIL
# Enable Rhel Yum repository
sudo amazon-linux-extras install epel -y
# Install Email client
sudo yum install ssmtp -y
# Delete current ssmtp conf if available
if [ -f /etc/ssmtp/ssmtp.conf ]
then
    sudo rm /etc/ssmtp/ssmtp.conf
    sudo rm /etc/ssmtp/revaliases
fi
# Copy email config from config s3 bucket
sudo aws s3 cp s3://capital-market-config-bucket/webserver/ssmtp.conf /etc/ssmtp/ssmtp.conf
sudo aws s3 cp s3://capital-market-config-bucket/webserver/revaliases /etc/ssmtp/revaliases

## WEBSERVER
# Create index.html with Hello World Header at /var/www/html/index.html
echo "<h1>Hello World</h1>" > /var/www/html/index.html
# Start httpd server
sudo systemctl start httpd
# Enable Auto start of httpd server in case of restarts
sudo chkconfig httpd

## LOGGING
# Create Logging Script dir
sudo mkdir -p /etc/logging/
# Copy logging script from config s3 bucket
sudo aws s3 cp s3://capital-market-config-bucket/webserver/logging.sh /etc/logging/script.sh
# Allow execute permission to script.sh
sudo chmod 755 /etc/logging/script.sh
# Configure crontab to run faily at 23:30
cat <<EOF > /cron.txt
30 23 * * * /etc/logging/script.sh >> /var/log/cron.log
EOF
sudo crontab /cron.txt
