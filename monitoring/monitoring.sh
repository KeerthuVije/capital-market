#!/bin/bash

# Function to send emails
function email () {
cat <<EOF | ssmtp keerthuvije@gmail.com
Subject: Monitoring Script Failed

$1
EOF
}

# DynamoDB Insert Array String start
strJson="["
# Get timestamp to be used as primary key
timestamp=$(date -u +%Y-%m-%d-%h:%M:%s)

# Get list of all instances in webserver-asg Autoscaling group
for line in $(aws autoscaling describe-auto-scaling-groups --output json --region us-east-1 --auto-scaling-group-names webserver-asg | jq -c ".AutoScalingGroups | .[0] | .Instances | .[]")
do
    # Default result is success
    result="success"
    # Get Instance ID from ASG describe output
    inId=$(echo $line | jq -r ".InstanceId")
    # Get Ip of Instance using gathered Instance Id
    inIp=$(aws ec2 describe-instances --region us-east-1 --instance-ids $inId --output text --query 'Reservations[*].Instances[*].[PrivateIpAddress]')
    # Debug print statement
    echo "Ip of instance $inId is $inIp"
    # SSH into specific instance and check if httpd is running else start
    ssh -i "/etc/monitoring/keerthan-key.pem" -oStrictHostKeyChecking=no -oIdentitiesOnly=yes ec2-user@$inIp "systemctl is-active httpd || sudo systemctl start httpd"
    # Check if SSH Failed, if so send mail
    if [ $? -ne 0 ]
    then
        # Set result to SSH failed
        result="Failed to SSH"
        # Send Email
        email "Failed for Instance $inId. Due to SSH Fail"
    fi
    # Try to get web content
    resp=$(curl -o /dev/null -s -w "%{http_code}\n" $inIp)
    # Check if http code is 200 (Success)
    if [ $resp -ne 200 ]
    then
        # Update result
        result="Failed to get web content"
        # Send Email
        email "Failed for Instance $inId. Due to bad status code when trying to get content : $resp"
    fi
    echo $result
    # Format StrJson according to DynamoDB required format
    strJson="$strJson{\"M\":{\"code\":{\"S\":\"$resp\"},\"ip\":{\"S\":\"$inIp\"},\"result\":{\"S\":\"$result\"}}},"
done

# Remove last comma from json
strJson=${strJson::-1}
# Add ending ] to str 
strJson="$strJson]"
echo $strJson

# Add Output to dynamoDB
aws dynamodb put-item --region us-east-1 --table-name webserver-monitoring --item "{\"timestamp\":{\"S\":\"$timestamp\"},\"response\":{\"L\":$strJson}}" --region us-east-1
 if [ $? -ne 0 ]
then
    # Send Email
    email "Failed to add data into DynamoDB at $timestamp"
fi