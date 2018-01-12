#!/bin/ksh +x
#        1         2         3         4         5         6         7         8         9
#234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
################################################################################
SCRIPT_NAME="aws-tk"
################################################################################
VERSION="0.35a"
AUTHOR="Orlando Hehl Rebelo dos Santos"
DATE_INI="10-01-2018"
DATE_END="12-01-2018"
################################################################################



PROFILE_USR=${1:-"a1"}
action=${2:-"DESCRIBE"}
port=${3:-"80"}

REGION="sa-east-1"
INSTANCE_USR="ec2-user"
SERVICE="ec2"
JSON_FMT="--output json"
AWS="aws --profile $PROFILE_USR --region $REGION"

BROWSER='open  -n -a "Google Chrome.app"  --args --new-window'

INSTANCES_TMP_FILE=.aws-shell.tmp
PEM_FILE=~/stuff/aws/ohrs-aws-sp-br.pem

printf "$SCRIPT_NAME $VERSION - $DATE_END  \n\n"

$AWS $JSON_FMT ec2 describe-instances > $INSTANCES_TMP_FILE

function load_instances_data {
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

   case $action in
       START_SSH )
           ssh -i $PEM_FILE $INSTANCE_USR@${public_dns_name[$target]}
           ;;
       START_BROWSER )
           $BROWSER http://${public_dns_name[$target]}:$port
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
describe_instances

if [[ $action != "DESCRIBE" ]]; then
   printf "Type the target instance number for the action: "
   read target
   run_action
fi


rm -f $INSTANCES_TMP_FILE

printf "\nbye!\n"

exit 0
