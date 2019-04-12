#!/bin/ksh
#        1         2         3         4         5         6         7         8         9         0
#2345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789
#######################################################################################################################
SCRIPT_NAME="aws-shell-tk"
#######################################################################################################################
SCRIPT_VERSION="0.67a"
AUTHOR="Orlando Hehl Rebelo dos Santos"
SCRIPT_DATE_INI="10-01-2018"
SCRIPT_DATE_END="03-04-2019"
#######################################################################################################################
printf "$SCRIPT_NAME $SCRIPT_VERSION - $SCRIPT_DATE_END  \n\n"

#######################################################################################################################
# Imports
#######################################################################################################################
AWS_SHELL_DIR="$OHRS_STUFF_PATH/aws-shell-tk"
OHRS_LIB_DIR="$OHRS_STUFF_PATH/lib/sh"
. $AWS_SHELL_DIR/ec2-aws-shell-tk.ksh
. $OHRS_LIB_DIR/colors-constants.sh


PROFILE_USR=""
REGION=""
OUTPUT_FRMT=""
SERVICE="ec2"
DESCRIBE=FALSE
EC2_ACTION=""
PORT="80"
DOCKER_PROFILE="ohrsan"
CONTAINER_VOLUME=""
OPTION_NUM=''

INSTANCE_USR="ec2-user"
#INSTANCE_NAME=""
BOOTSTRAP_FILE=./meteor-user-data.template.txt
KEY_PAIR="ohrs-aws-sp-br"
AMI_ID="ami-3d4d0f51"

usage(){
        echo $SCRIPT_NAME
#	echo "Usage: $SCRIPT_NAME.ksh [-u profile] [-r region] [-s service] [-l] [-a action] \
 #                                     [-P port] [-N container-name] [-t container-tag]\
  #                                    [-V container-volume] [-U docker-profile] [-T bootstrap-file]\
   #                                   [-I ami-instance-id"] [-k key-pair] [-n instance-name] "
	echo "  -u   Set AWS user profile name"
	echo "  -r   Region"
	echo "  -O   Output format"
	echo "  -o   Option number for noninteractivity"
	echo "  -s   Service: ec2|s3|rds"
	echo "  -l   List instances"
	echo "  -a   Action to apply to EC2 instances: ssh|scp|browser|run|start|stop|terminate"
	echo "  -P   TCP port number for the browser and container app published TCP port map"
	echo "  -N   Container application name"
	echo "  -t   Container application tag preceded by \":\""
	echo "  -V   Container application volume"
	echo "  -U   Set Docker user profile name"
	echo "  -T   Name of the bootstrap file"
	echo "  -I   AMI instance id for instance instantiation"
	echo "  -L   Instance user"
	echo "  -K   specify key pair"
	echo "  -n   specify instance name"
	echo "  -h   Print help and exit"
}

while getopts "u:r:s:la:P:N:t:V:T:I:K:n:L:O:o:vh" arg
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
	        L)
                INSTANCE_USR="${OPTARG}"
                ;;
	        O)
                OUTPUT_FRMT="--output ${OPTARG}"
                ;;
	        o)
                OPTION_NUM="${OPTARG}"
                ;;
            v)
                echo "${AWS_SHELL_TK_VERSION}"
                exit 0
                ;;
            h|*)
                usage
                exit 1
                ;;
        esac
done

shift $(($OPTIND - 1))


function cleanup {
    if [[ -e $INSTANCES_TMP_FILE ]]; then
        rm -f $INSTANCES_TMP_FILE
        echo; echo "Action aborted, exiting..."
    fi
    exit 0
}

trap cleanup INT TERM
if [[ $EC2_ACTION == "SCP_INSTANCE" ]]; then
    if [[ -n $1 ]] && [[ -n $2 ]]; then
        LOCAL_FILE="$1"
        REMOTE_FILE="$2"
    else
       echo "Incorrect argumentos to scp"
       usage
    fi
fi

if [[ $EC2_ACTION == "SR-CMD_INSTANCE" ]]; then
    if [[ -n $1 ]]; then
        SR_CMD="$1"
    else
       echo "Incorrect argumentos to security remote command"
       usage
    fi
fi

JSON_FMT="--output json"
AWS="aws $PROFILE_USR $REGION $OUTPUT_FRMT"
BROWSER="open  -n -a \"Google Chrome.app\"  --args --new-window"

INSTANCES_TMP_FILE=.aws-shell.tmp
PEM_FILE=${KEY_PAIR}



load_instances_data

if [[ $DESCRIBE == TRUE ]]; then
      describe_instances
fi

if [[ $EC2_ACTION == "RUN_INSTANCE" ]]; then
   run_ec2_action
elif [[ -n $EC2_ACTION ]]; then
    if [[ -z $OPTION_NUM ]]; then
       printf "Type the target instance number for the action: "
       read target
   else
       target=$OPTION_NUM
   fi
   run_ec2_action
fi


rm -f $INSTANCES_TMP_FILE

printf "\nbye!\n"

exit 0
#######################################################################################################################

