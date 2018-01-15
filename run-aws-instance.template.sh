#!/bin/ksh
#        1         2         3         4         5         6         7         8         9
#234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
################################################################################
SCRIPT_NAME="run-aws-instance.template"
#This script is a template to be modified and "save as" for the specific
#instance launch. Note that it contains variables and container run command
#if container will not be used, dissmis those parametrization accordantly
################################################################################
VERSION="0.01a"
AUTHOR="Orlando Hehl Rebelo dos Santos"
DATE_INI="14-01-2018"
DATE_END="14-01-2018"
################################################################################
#Changes:
#
################################################################################


################################################################################
#sonfiguration section:
#
PROFILE_USR="a1"
REGION="sa-east-1"

INSTANCE_KEY_PAIR="ohrs-aws-sp-br"
INSTANCE_SECURITY_GRP="ohrs-default"
INSTANCE_NAME="container-b"
INSTANCE_USR="ec2-user"
INSTANCE_AMI_ID="ami-3d4d0f51"
INSTANCE_TYPE="t2.micro"
INSTANCE_COUNT="1"
INSTANCE_DATA_FILE="user-data.txt"

DOCKER_PROFILE="ohrsan"
CONTAINER_APP_NAME="meteor-container-b"
CONTAINER_MNT_VOLUME="/var/meteor/app"
CONTAINER_TAG="1"
CONTAINER_PORT="3332"

################################################################################


################################################################################
# Macros:
AWS="aws --profile $PROFILE_USR --region $REGION"

INSTANCES_TMP_FILE=".aws-shell.tmp"

if [[ -n $CONTAINER_MNT_VOLUME ]]; then
   CONTAINER_MNT_VOLUME=" -v $CONTAINER_MNT_VOLUME"
fi
################################################################################
# Insert/Delete or change the lines as desired of the 'user_data" array bellow:

user_data=(

"#!/bin/bash"

#Update the installed packages and package cache on your instance."
"yum update -y"

#set locale"
"localectl set-locale LANG=en_US.utf8"

#Install the most recent Docker Community Edition package."
"yum install -y docker"

#Add the ec2-user to the docker group so you can execute Docker commands without using sudo."
"usermod -a -G docker ec2-user"

#Start the Docker service."
"service docker start"

#Automatic docker service startup
"chkconfig docker on"

"chmod +x /etc/rc.d/rc.local"

#/usr/bin/docker start meteor-container-a-app-1
"echo sleep 5 >> /etc/rc.d/rc.local"
"echo \"for (( i = 0 ; i < 10; i++ )); do\" >> /etc/rc.d/rc.local"
"echo \"    pgrep dockerd && /usr/bin/docker start meteor-container-a-app-1 > /home/ec2-user/docker.log 2>&1; exit 0\" >> /etc/rc.d/rc.local"
"echo \"    echo sleeping 3 seconds...\" >> /etc/rc.d/rc.local"
"echo \"    sleep 3\" >> /etc/rc.d/rc.local"
"echo \"done\" >> /etc/rc.d/rc.local"

# Docker run command ..."
"su $INSTANCE_USR -c \"docker run -d -p ${CONTAINER_PORT}:3000 $CONTAINER_MNT_VOLUME --name ${CONTAINER_APP_NAME}-app-${CONTAINER_TAG} ${DOCKER_PROFILE}/${CONTAINER_APP_NAME}-app:${CONTAINER_TAG}\""

)


################################################################################
# user-data file section:

> $INSTANCE_DATA_FILE
for index in "${!user_data[@]}"; do 
    echo "${user_data[$index]}" >> $INSTANCE_DATA_FILE
    echo "${user_data[$index]}" 
done

    
    echo "Initializing instance..."
    new_image_id=$($AWS --output json ec2 run-instances --image-id  $INSTANCE_AMI_ID --count $INSTANCE_COUNT --instance-type $INSTANCE_TYPE --key-name $INSTANCE_KEY_PAIR --security-groups $INSTANCE_SECURITY_GRP --user-data file://$(pwd)/$INSTANCE_DATA_FILE --tag-specifications "[ { \"ResourceType\": \"instance\", \"Tags\": [ { \"Key\": \"Name\", \"Value\": \"${INSTANCE_NAME}\" } ] } ] " | grep InstanceId  | tr -d ' ",' | awk -F: '{print $2}')
    
    echo "Instance created, summary:"
    $AWS ec2 describe-instances --filters "Name=instance-id, Values=$new_image_id"


exit 0
################################################################################
