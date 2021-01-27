#!/bin/bash

#Create name for the object to be stored in s3
dateName=$(date -u +%Y-%m-%d)
# Change to log script directory
cd /etc/logging/
# Delete if already log directory is there. Redirect all output to /dev/null
rm -rf logDir &> /dev/null
# Create Fresh Directory
mkdir logDir
# Copy httpd Server logs to Log Directory
cp /var/log/httpd/* ./logDir/
# Get Server Content
curl localhost > ./logDir/content.html

# Compress Collected log files and content
tar -cvzf "log-$dateName.tar.gz" ./logDir

# Delete temp logDir Directory
rm -rf ./logDir

# Copy Compresed log files to S3
aws s3 cp "/etc/logging/log-$dateName.tar.gz" s3://capital-market-logging-bucket/webserver/

# Check if AWS S3 Copy Failed
if [ $? -ne 0 ]
then
cat <<EOF | ssmtp keerthuvije@gmail.com
Subject: Log File Copy Failed

Log file copy to AWS S3 for the date : $dateName has failed.
EOF
else
    rm "/etc/logging/log-$dateName.tar.gz"
fi
