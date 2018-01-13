#!/bin/ksh +x
#        1         2         3         4         5         6         7         8         9
#234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
################################################################################
SCRIPT_NAME="aws-shell-tk"
################################################################################
VERSION="0.55a"
AUTHOR="Orlando Hehl Rebelo dos Santos"
DATE_INI="10-01-2018"
DATE_END="12-01-2018"
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
################################################################################



PROFILE_USR=""
REGION=""
SERVICE="ec2"
DESCRIBE=FALSE
ACTION=""
PORT="80"
DOCKER_PROFILE="ohrsan"

INSTANCE_USR="ec2-user"
KEY_PAIR="ohrs-aws-sp-br"
AMI_ID="ami-3d4d0f51"

usage(){
        echo $SCRIPT_NAME
	echo "Usage: $SCRIPT_NAME.ksh [-u profile] [-r region] [-s service] [-l] [-a action] [-P port] [-N container-name] [-t container-tag] [-V container-volume] [-U docker-profile] [-T bootstrap-file] [-I ami-instance-id"] [-k key-pair]"
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
	echo "  -h   Print help and exit"
}

while getopts "u:r:s:la:P:N:t:V:T:I:K:vh" arg
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
                ACTION="${OPTARG}_INSTANCE"
                typeset -u ACTION

                SERVICE="ec2"
                ;;
            P)
                PORT=${OPTARG}
                ;;
            N)
                CONTAINER_APP_NAME=${OPTARG}
                ;;
            t)
                CONTAINER_TAG=${OPTARG}
                ;;
            V)
                CONTAINER_VOLUME=${OPTARG}
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
. ./aws-ec2-run-instance.sh


#function load_instances_data {
#    $AWS $JSON_FMT ec2 describe-instances > $INSTANCES_TMP_FILE
#    i=0
#    while [[ $(jq ".Reservations | .[$i] | .Instances |. [0] |  .State.Name" < $INSTANCES_TMP_FILE ) != "null" ]]; do
#    
#       instance_id[$i]=$(jq ".Reservations | .[$i] | .Instances |. [0] |  .InstanceId" < $INSTANCES_TMP_FILE | tr -d ' "')
#       state[$i]=$(jq ".Reservations | .[$i] | .Instances | .[0] |  .State.Name" < $INSTANCES_TMP_FILE | tr -d ' "')
#
#       launch_time[$i]=$(jq ".Reservations | .[$i] | .Instances | .[0] |  .LaunchTime" < $INSTANCES_TMP_FILE | tr -d ' "')
#       #if [[ -z ${launch_time[$i]} ]]; then launch_time[$i]="        ---        "; fi
#    
#       public_dns_name[$i]=$(jq ".Reservations | .[$i] | .Instances | .[0] |  .PublicDnsName" < $INSTANCES_TMP_FILE | tr -d ' "')
#       if [[ -z ${public_dns_name[$i]} ]]; then public_dns_name[$i]="---"; fi
#    
#       instance_name[$i]=$(jq ".Reservations | .[$i] | .Instances | .[0] |  .Tags | .[0] | .Value" < $INSTANCES_TMP_FILE | tr -d ' "')
#       if [[ -z ${instance_name[$i]} ]]; then instance_name[$i]="---"; fi
#
#       ((i++))
#    done
#}
#    
#function describe_instances {
#       printf "%-4s%-21s%-16s%-26s%-51s%-12s\n"  "No" "INSTANCE_ID" "STATE" "LAUNCH_TIME" "PUBLIC_DNS" "INSTANCE_NAME"
#       for (( j=0; $j < $i; j++ )); do
#           printf "%02u  %-21s%-16s%-26s%-51s%-12s\n" $j\
#                                                               ${instance_id[$j]}\
#                                                               ${state[$j]}\
#                                                               ${launch_time[$j]}\
#                                                               ${public_dns_name[$j]}\
#                                                               ${instance_name[$j]}
#        done
#    
#}

function run_action {

   case $ACTION in
       SSH_INSTANCE )
           ssh -i $PEM_FILE $INSTANCE_USR@${public_dns_name[$target]}
           ;;
       BROWSER_INSTANCE )
           eval $BROWSER http://${public_dns_name[$target]}:$PORT
           ;;
       RUN_INSTANCE )
           run_instance
           ;;
       START_INSTANCE )
           $AWS ec2 start-instances --instance-ids  ${instance_id[$target]}
           ;;
       STOP_INSTANCE )
           $AWS ec2 stop-instances --instance-ids  ${instance_id[$target]}
           ;;
       TERMINATE_INSTANCE )
           $AWS ec2 terminate-instances --instance-ids  ${instance_id[$target]}
           ;;
        *   )
           echo "Default action."
   esac
}


load_instances_data

if [[ $DESCRIBE == TRUE ]]; then
      describe_instances
fi

if [[ $ACTION == "RUN_INSTANCE" ]]; then
   run_action
elif [[ -n $ACTION ]]; then
   printf "Type the target instance number for the action: "
   read target
   run_action
fi


rm -f $INSTANCES_TMP_FILE

printf "\nbye!\n"

exit 0
################################################################################

