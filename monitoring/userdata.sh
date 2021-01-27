#!/bin/bash

configBucket="capital-market-config-bucket"
keyName="keerthan-pem.pem"

## COMMON
# update yum packages 
sudo yum update -y
sudo yum install jq -y

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
sudo aws s3 cp s3://$configBucket/monitoring/ssmtp.conf /etc/ssmtp/ssmtp.conf
sudo aws s3 cp s3://$configBucket/monitoring/revaliases /etc/ssmtp/revaliases


## MONITORING
# Create Script dir
sudo mkdir -p /etc/monitoring/
# Copy script from config s3 bucket
sudo aws s3 cp s3://$configBucket/monitoring/monitoring.sh /etc/monitoring/script.sh
# Copy ssh key from config bucket
sudo aws s3 cp s3://$configBucket/monitoring/   .pem /etc/monitoring/keerthan-key.pem
sudo chmod 400 /etc/monitoring/keerthan-key.pem

# Allow execute permission to script.sh
sudo chmod 755 /etc/monitoring/script.sh
# Configure crontab to run faily at 23:30
cat <<EOF > /cron.txt
5 0-23 * * * /etc/monitoring/script.sh >> /var/log/cron.log
EOF
sudo crontab /cron.txt
