#!/bin/ksh
#        1         2         3         4         5         6         7         8         9
#234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
################################################################################
SCRIPT_NAME="run-aws-instance.template"
#This script is a template to be modified and "save as" for the specific
#instance launch. Note that it contains variables and container run command
#if container will not be used, dissmis those parametrization accordantly
################################################################################
VERSION="0.03a"
AUTHOR="Orlando Hehl Rebelo dos Santos"
DATE_INI="14-01-2018"
DATE_END="15-01-2018"
################################################################################
#Changes:
#
################################################################################


################################################################################
#Configuration section:
#
PROFILE_USR="a1"
REGION="sa-east-1"

INSTANCE_DRY_RUN="--dry-run" #Comment this hole line to enable processing 
INSTANCE_KEY_PAIR="ohrs-aws-sp-br"
INSTANCE_SECURITY_GRP="ohrs-default"
INSTANCE_NAME="jenkins-tutorial"
INSTANCE_USR="ec2-user"
INSTANCE_AMI_ID="ami-3d4d0f51"
INSTANCE_TYPE="t2.micro"
INSTANCE_COUNT="1"
INSTANCE_DATA_FILE="user-data.txt"

DOCKER_PROFILE="jenkinsci"
CONTAINER_REPO="blueocean"
CONTAINER_APP_NAME="jenkins"
CONTAINER_TAG=""
#These options bellow due to their many variations,
#requires that you provide the necessary flags.
CONTAINER_MNT_VOLUME="-v jenkins-data:/var/jenkins_home -v jenkins-data:/var/jenkins_home -v \$HOME:/home"
CONTAINER_PORT="-p 8080:8080"
CONTAINER_OTHERS="-u root"
################################################################################


################################################################################
# Macros:
AWS="aws --profile $PROFILE_USR --region $REGION"

INSTANCES_TMP_FILE=".aws-shell.tmp"

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
"echo \"    pgrep dockerd && /usr/bin/docker start ${CONTAINER_APP_NAME}-app-${CONTAINER_TAG} > /home/$INSTANCE_USR/${CONTAINER_APP_NAME}-app-${CONTAINER_TAG}.docker.log 2>&1; chmod 777 /home/$INSTANCE_USR/${CONTAINER_APP_NAME}-app-${CONTAINER_TAG}.docker.log; exit 0\" >> /etc/rc.d/rc.local"
"echo \"    echo sleeping 3 seconds...\" >> /etc/rc.d/rc.local"
"echo \"    sleep 3\" >> /etc/rc.d/rc.local"
"echo \"done\" >> /etc/rc.d/rc.local"

# Docker run command ..."
"su $INSTANCE_USR -c \"docker run -d ${CONTAINER_PORT} $CONTAINER_MNT_VOLUME --name ${CONTAINER_APP_NAME}-app-${CONTAINER_TAG} ${CONTAINER_OTHERS} ${DOCKER_PROFILE}/${CONTAINER_REPO}${CONTAINER_TAG}\""

)


################################################################################
# user-data file section:

> $INSTANCE_DATA_FILE
for index in "${!user_data[@]}"; do 
    echo "${user_data[$index]}" >> $INSTANCE_DATA_FILE
    echo "${user_data[$index]}" 
done
    echo "Initializing instance..."
    new_image_id=$($AWS --output json ec2 run-instances $INSTANCE_DRY_RUN --image-id  $INSTANCE_AMI_ID --count $INSTANCE_COUNT --instance-type $INSTANCE_TYPE --key-name $INSTANCE_KEY_PAIR --security-groups $INSTANCE_SECURITY_GRP --user-data file://$(pwd)/$INSTANCE_DATA_FILE --tag-specifications "[ { \"ResourceType\": \"instance\", \"Tags\": [ { \"Key\": \"Name\", \"Value\": \"${INSTANCE_NAME}\" } ] } ] " | grep InstanceId  | tr -d ' ",' | awk -F: '{print $2}')
    
    echo "Instance created, summary:"
    $AWS ec2 describe-instances --filters "Name=instance-id, Values=$new_image_id"


exit 0
################################################################################
