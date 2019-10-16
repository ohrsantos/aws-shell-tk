#!/bin/ksh
#        1         2         3         4         5         6         7         8         9         0
#2345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789
#######################################################################################################################
AWS_SHELL_TK_SCRIPT_NAME="aws-shell-tk"
#######################################################################################################################
SCRIPT_VERSION="0.76a"
AUTHOR="Orlando Hehl Rebelo dos Santos"
SCRIPT_DATE_INI="10-01-2018"
SCRIPT_DATE_END="16-09-2019"
#######################################################################################################################

#######################################################################################################################
# Imports
#######################################################################################################################
if [ -n "$OHRS_STUFF_PATH" ]; then 
    AWS_SHELL_TK_DIR="$OHRS_STUFF_PATH/aws-shell-tk"
    #OHRS_LIB_DIR="$OHRS_STUFF_PATH/lib/sh"
    source $OHRS_STUFF_PATH/etc/color-constants.sh
fi
source $AWS_SHELL_TK_DIR/ec2-aws-shell-tk.ksh

if [ -f "$AWS_SHELL_TK_DIR/color-constants.sh" ]; then
    source $AWS_SHELL_TK_DIR/color-constants.sh
fi

printf "$AWS_SHELL_TK_SCRIPT_NAME $SCRIPT_VERSION/$EC2_AWS_SHELL_TK_VERSION - $SCRIPT_DATE_END  \n\n"

PROFILE_USR=""
REGION=""
OUTPUT_FRMT=""
SERVICE="ec2"
DESCRIBE=FALSE
EC2_ACTION=""
PORT="80"
target=''

INSTANCE_USR="ubuntu"
KEY_PAIR="ohrs-aws-sp-br"

usage(){
        echo $SCRIPT_NAME
#	echo "Usage: $SCRIPT_NAME.ksh [-u profile] [-r region] [-s service] [-l] [-a action] \
 #                                     [-P port] [-N container-name] [-t container-tag]\
  #                                    [-V container-volume] [-U docker-profile] [-T bootstrap-file]\
   #                                   [-I ami-instance-id"] [-k key-pair] [-n instance-name] "
	echo "  -P   Set AWS user profile name"
	echo "  -R   Region"
	echo "  -O   Output format"
	echo "  -o   Option number for noninteractivity mode"
	echo "  -s   Service: ec2|s3|rds"
	echo "  -l   List instances"
	echo "  -a   Action to apply to EC2 instances: ssh|scp|browser|run|start|stop|terminate"
	echo "  -p   TCP port number for the browser and container app published TCP port map"
	echo "  -u   Instance user"
	echo "  -k   specify key pair"
	echo "  -v   Print version and exit"
	echo "  -h   Print help and exit"
}

while getopts "u:R:s:la:P:k:O:o:p:vh" arg
do
        case $arg in
            P)
                PROFILE_USR="--profile $OPTARG"
                ;;
            R)
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
            p)
                PORT=${OPTARG}
                ;;
            k)
                KEY_PAIR=${OPTARG}
                ;;
	        u)
                INSTANCE_USR="${OPTARG}"
                ;;
	        O)
                OUTPUT_FRMT="--output ${OPTARG}"
                ;;
	        o)
                target="${OPTARG}"
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

if [[ $EC2_ACTION == "RCMD_INSTANCE" ]]; then
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
    if [[ -z $target ]]; then
       printf "Type the target instance number for the action: "
       read target
    fi
    run_ec2_action
elif [[ -n $EC2_ACTION ]]; then
    if [[ -z $target ]]; then
       printf "Type the target instance number for the action: "
       read target
    fi
    run_ec2_action
fi


rm -f $INSTANCES_TMP_FILE

printf "\nbye!\n"

exit 0
#######################################################################################################################

