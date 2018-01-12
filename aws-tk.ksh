#!/bin/ksh +x
#        1         2         3         4         5         6         7         8         9
#234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
################################################################################
SCRIPT_NAME="aws-tk"
################################################################################
VERSION="0.47a"
AUTHOR="Orlando Hehl Rebelo dos Santos"
DATE_INI="10-01-2018"
DATE_END="12-01-2018"
################################################################################
#Changes:
#
#12-01-2018 - getopts initial structure
#12-01-2018 - add create action (not working)
################################################################################



PROFILE_USR=""
REGION=""
SERVICE="ec2"
DESCRIBE=FALSE
ACTION=""
PORT="80"

INSTANCE_USR="ec2-user"

usage(){
        echo $SCRIPT_NAME
	echo "Usage: $SCRIPT_NAME.ksh [-u profile] [-r region] [-s service] [-l] [-a action]"
	echo "  -u   Set the user profile name"
	echo "  -r   Region"
	echo "  -s   Service: ec2|s3|rds"
	echo "  -l   List instances"
	echo "  -a   Action to apply to EC2 instances: ssh|browser|create|start|stop|terminate"
	echo "  -h   Print help and exit"
}

while getopts "u:r:s:la:vh" arg
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
BROWSER='open  -n -a "Google Chrome.app"  --args --new-window'

INSTANCES_TMP_FILE=.aws-shell.tmp
PEM_FILE=~/stuff/aws/ohrs-aws-sp-br.pem


################################################################################
# Imports
################################################################################


function load_instances_data {
    $AWS $JSON_FMT ec2 describe-instances > $INSTANCES_TMP_FILE
    i=0
    while [[ $(jq ".Reservations | .[$i] | .Instances |. [0] |  .State.Name" < $INSTANCES_TMP_FILE ) != "null" ]]; do
    
       instance_id[$i]=$(jq ".Reservations | .[$i] | .Instances |. [0] |  .InstanceId" < $INSTANCES_TMP_FILE | tr -d ' "')
       state[$i]=$(jq ".Reservations | .[$i] | .Instances | .[0] |  .State.Name" < $INSTANCES_TMP_FILE | tr -d ' "')

       launch_time[$i]=$(jq ".Reservations | .[$i] | .Instances | .[0] |  .LaunchTime" < $INSTANCES_TMP_FILE | tr -d ' "')
       #if [[ -z ${launch_time[$i]} ]]; then launch_time[$i]="        ---        "; fi
    
       public_dns_name[$i]=$(jq ".Reservations | .[$i] | .Instances | .[0] |  .PublicDnsName" < $INSTANCES_TMP_FILE | tr -d ' "')
       if [[ -z ${public_dns_name[$i]} ]]; then public_dns_name[$i]="---"; fi
    
       instance_name[$i]=$(jq ".Reservations | .[$i] | .Instances | .[0] |  .Tags | .[0] | .Value" < $INSTANCES_TMP_FILE | tr -d ' "')
       if [[ -z ${instance_name[$i]} ]]; then instance_name[$i]="---"; fi

       ((i++))
    done
}
    
function describe_instances {
       printf "%-4s%-21s%-16s%-26s%-51s%-12s\n"  "No" "INSTANCE_ID" "STATE" "LAUNCH_TIME" "PUBLIC_DNS" "INSTANCE_NAME"
       for (( j=0; $j < $i; j++ )); do
           printf "%02u  %-21s%-16s%-26s%-51s%-12s\n" $j\
                                                               ${instance_id[$j]}\
                                                               ${state[$j]}\
                                                               ${launch_time[$j]}\
                                                               ${public_dns_name[$j]}\
                                                               ${instance_name[$j]}
        done
    
}

function run_action {

   case $ACTION in
       SSH_INSTANCE )
           ssh -i $PEM_FILE $INSTANCE_USR@${public_dns_name[$target]}
           ;;
       BROWSER_INSTANCE )
           $BROWSER http://${public_dns_name[$target]}:$PORT
           ;;
       CREATE_INSTANCE )
           . ./aws-ec2-create-instance.sh
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
if [[ -n $ACTION ]]; then
   printf "Type the target instance number for the action: "
   read target
   run_action
fi


rm -f $INSTANCES_TMP_FILE

printf "\nbye!\n"

exit 0
################################################################################

