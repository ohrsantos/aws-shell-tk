#!/bin/ksh +x
#        1         2         3         4         5         6         7         8         9
#234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
################################################################################
SCRIPT_NAME="shell-tk-aws"
################################################################################
VERSION="0.59a"
AUTHOR="Orlando Hehl Rebelo dos Santos"
DATE_INI="10-01-2018"
DATE_END="13-01-2018"
################################################################################
#Changes:
#
#12-01-2018 - getopts initial structure
#12-01-2018 - add create action (not working)
#12-01-2018 - added -P flag for TCP port number
#12-01-2018 - added -N -t -V -U -T -k flags
#12-01-2018 - disabled instance inquiry for run action
#13-01-2018 - Changed script name
#13-01-2018 - Changed the call to run instance to a function
#13-01-2018 - Moved load and describe functions to aws-ec2-run-instance.sh module
#13-01-2018 - Changed script name
#13-01-2018 - added -n flag
#15-01-2018 - added $AWS_SHELL_DIR
################################################################################

AWS_SHELL_DIR="/Users/ohrs/stuff/aws/aws-shell-tk"

PROFILE_USR=""
REGION=""
SERVICE="ec2"
DESCRIBE=FALSE
EC2_ACTION=""
PORT="80"
DOCKER_PROFILE="ohrsan"
CONTAINER_VOLUME=""

INSTANCE_USR="ec2-user"
#INSTANCE_NAME=""
BOOTSTRAP_FILE=./meteor-user-data.template.txt
KEY_PAIR="ohrs-aws-sp-br"
AMI_ID="ami-3d4d0f51"

usage(){
        echo $SCRIPT_NAME
	echo "Usage: $SCRIPT_NAME.ksh [-u profile] [-r region] [-s service] [-l] [-a action] [-P port] [-N container-name] [-t container-tag] [-V container-volume] [-U docker-profile] [-T bootstrap-file] [-I ami-instance-id"] [-k key-pair] [-n instance-name]"
	echo "  -u   Set AWS user profile name"
	echo "  -r   Region"
	echo "  -s   Service: ec2|s3|rds"
	echo "  -l   List instances"
	echo "  -a   Action to apply to EC2 instances: ssh|browser|run|start|stop|terminate"
	echo "  -P   TCP port number for the browser and container app published TCP port map"
	echo "  -N   Container application name"
	echo "  -t   Container application tag"
	echo "  -V   Container application volume"
	echo "  -U   Set Docker user profile name"
	echo "  -T   Name of the bootstrap file"
	echo "  -I   AMI instance id for instance instantiation
	echo "  -K   specify key pair"
	echo "  -n   specify instance name"
	echo "  -h   Print help and exit"
}

while getopts "u:r:s:la:P:N:t:V:T:I:K:n:vh" arg
do
        case $arg in
            u)
                PROFILE_USR="--profile $OPTARG"
                ;;
            r)
                REGION="--region $OPTARG"
                ;;
            s)
                DESCRIBE=TRUE
                ;;
            l)
                DESCRIBE=TRUE
                ;;
            a)
                EC2_ACTION="${OPTARG}_INSTANCE"
                typeset -u EC2_ACTION

                SERVICE="ec2"
                ;;
            P)
                PORT=${OPTARG}
                ;;
            N)
                CONTAINER_APP_NAME=${OPTARG}
                if [[ -z $INSTANCE_NAME ]]; then INSTANCE_NAME=$CONTAINER_APP_NAME; fi
                ;;
            t)
                CONTAINER_TAG=${OPTARG}
                ;;
            V)
                if [[ -n ${OPTARG} ]]; then
                    CONTAINER_VOLUME="-v ${OPTARG}"
                fi
                ;;
            u)
                DOCKER_PROFILE=$OPTARG
                ;;
            T)
                BOOTSTRAP_FILE=${OPTARG}
                ;;
            I)
                AMI_ID=${OPTARG}
                ;;
            K)
                KEY_PAIR=${OPTARG}
                ;;
            n)
                INSTANCE_NAME="${OPTARG}"
                ;;
            v)
                echo "${VERSION}"
                exit 0
                ;;
            h|*)
                usage
                exit 1
                ;;
        esac
done

shift $(($OPTIND - 1))

printf "$SCRIPT_NAME $VERSION - $DATE_END  \n\n"

JSON_FMT="--output json"
AWS="aws $PROFILE_USR $REGION"
BROWSER="open  -n -a \"Google Chrome.app\"  --args --new-window"

INSTANCES_TMP_FILE=.aws-shell.tmp
PEM_FILE=~/stuff/aws/${KEY_PAIR}.pem



################################################################################
# Imports
################################################################################
. $AWS_SHELL_DIR/ec2-shell-tk-aws.ksh


load_instances_data

if [[ $DESCRIBE == TRUE ]]; then
      describe_instances
fi

if [[ $EC2_ACTION == "RUN_INSTANCE" ]]; then
   run_ec2_action
elif [[ -n $EC2_ACTION ]]; then
   printf "Type the target instance number for the action: "
   read target
   run_ec2_action
fi


rm -f $INSTANCES_TMP_FILE

printf "\nbye!\n"

exit 0
################################################################################

