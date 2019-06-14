#!/bin/ksh           
#        1         2         3         4         5         6         7         8         9         0
#2345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789
#######################################################################################################################
SCRIPT_NAME="ec2-aws-shell-tk"
#######################################################################################################################
EC2_AWS_SHELL_TK_VERSION="0.60a"
AUTHOR="Orlando Hehl Rebelo dos Santos"
DATE_INI="10-01-2018"
DATE_END="13-06-2019"
#######################################################################################################################

function load_instances_data {
    $AWS $JSON_FMT ec2 describe-instances > $INSTANCES_TMP_FILE

    i=0; j=0; z=0 
    while [[ $(jq ".Reservations[$i].Instances[$j].State.Name" < $INSTANCES_TMP_FILE ) != "null" ]]; do
    while [[ $(jq ".Reservations[$i].Instances[$j].State.Name" < $INSTANCES_TMP_FILE ) != "null" ]]; do
    
       instance_id[$z]=$(jq ".Reservations[$i].Instances[$j].InstanceId" < $INSTANCES_TMP_FILE | tr -d ' "')

       instance_state[$z]=$(jq ".Reservations[$i].Instances[$j].State.Name" < $INSTANCES_TMP_FILE | tr -d ' "')

       instance_launch_time[$z]=$(jq ".Reservations[$i].Instances[$j].LaunchTime" < $INSTANCES_TMP_FILE | tr -d ' "')
    
       instance_public_ip[$z]=$(jq ".Reservations[$i].Instances[$j].PublicIpAddress" < $INSTANCES_TMP_FILE | tr -d ' "')
       if [[ ${instance_public_ip[$z]} == "null" ]]; then instance_public_ip[$z]="---"; fi
    
       instance_private_ip[$z]=$(jq ".Reservations[$i].Instances[$j].PrivateIpAddress" < $INSTANCES_TMP_FILE | tr -d ' "')
       if [[ ${instance_private_ip[$z]} == "null" ]]; then instance_private_ip[$z]="---"; fi
    
       tag_id=0
       while [[ $(jq ".Reservations[$i].Instances[$j].Tags[$tag_id].Key" < $INSTANCES_TMP_FILE ) != "null" ]]; do
           instance_tag_key=$(jq ".Reservations[$i].Instances[$j].Tags[$tag_id].Key" < $INSTANCES_TMP_FILE | tr -d ' "')
           if [[ ${instance_tag_key} == "Name" ]]; then
               instance_name[$z]=$(jq ".Reservations[$i].Instances[$j].Tags[$tag_id].Value" < $INSTANCES_TMP_FILE | tr -d ' "')
               break
           else
               instance_name[$z]="---"
           fi
           tag_id=$((tag_id+1))
       done


       instance_type[$z]=$(jq ".Reservations[$i].Instances[$j].InstanceType" < $INSTANCES_TMP_FILE | tr -d ' "')
       instance_subnet[$z]=$(jq ".Reservations[$i].Instances[$j].SubnetId" < $INSTANCES_TMP_FILE | tr -d ' "')
       instance_vpc[$z]=$(jq ".Reservations[$i].Instances[$j].VpcId" < $INSTANCES_TMP_FILE | tr -d ' "')
       instance_key_name[$z]=$(jq ".Reservations[$i].Instances[$j].KeyName" < $INSTANCES_TMP_FILE | tr -d ' "')
       instance_image_id[$z]=$(jq ".Reservations[$i].Instances[$j].ImageId" < $INSTANCES_TMP_FILE | tr -d ' "')

       j=$((j+1))
       z=$((z+1))
    done
       j=0 
       i=$((i+1))
    done
}
    
function describe_instances {
    printf "%-4s%-23s%-21s%-12s%-19s%-17s%-17s%-20s%-20s%-20s%-16s%-20s\n"\
           "No" "INSTANCE_NAME" "INSTANCE_ID" "STATE" "LAUNCH_TIME" "PRIVATE_IP" "PUBLIC_IP " "VPC_ID"  "SUB_NET_ID"  "KEY_NAME" "INSTANCE_TYPE" "IMAGE_ID"
    #for (( j=0; $j < $i; j++ )); do
    j=0
    while [[ $j -lt $z ]]; do
    
       typeset -u instance_state_=${instance_state[$j]}
       typeset -L10 instance_state_
       typeset -L22 instance_name_=${instance_name[$j]}
       typeset -L19 instance_launch_time_=${instance_launch_time[$j]}
       typeset -L17 instance_key_name_=${instance_key_name[$j]}
       instance_id_=${instance_id[$j]:2:17}
       instance_subnet_=${instance_subnet[$j]:7:17}
       instance_vpc_=${instance_vpc[$j]:4:17}
       instance_image_id_=${instance_image_id[$j]:4:17}

       case $instance_state_ in
           'STOPPED   ' ) state_color="${D_RED}";       __instance_state_=' STOPPED    ';;
           'RUNNING   ' ) state_color="${D_LGREEN}";    __instance_state_=' RUNNING    ';;
           'TERMINATED' ) state_color="${D_LIGHTGRAY}"; __instance_state_='TERMINATED  ';;
           'STOPPING  ' ) state_color="${D_YELLOW}";    __instance_state_=' STOPPING   ';;
           'PENDING   ' ) state_color="${D_YELLOW}";    __instance_state_=' PENDING    ';;
           'SHUTTING-D' ) state_color="${D_YELLOW}";    __instance_state_='SHUTTING-D  ';;
           *            ) state_color="${C_RST}";     __instance_state_=' STOPPING   ' ;;
       esac

       printf "${WHITE}%02u${C_RST}  %-23s%-19s${state_color}%s${C_RST}%-21s%-17s%-17s%-20s%-20s%-20s%-16s%-20s\n" \
                   $j\
                   ${instance_name_}\
                   "${instance_id_}"\
                   "${__instance_state_}"\
                   ${instance_launch_time_}\
                   ${instance_private_ip[$j]}\
                   ${instance_public_ip[$j]}\
                   ${instance_vpc_}\
                   ${instance_subnet_}\
                   ${instance_key_name_}\
                   ${instance_type[$j]}\
                   ${instance_image_id_}
       j=$((j+1))
    done
}

function run_instance {
    echo "Creating user-data.txt file ..."
    cp -f $BOOTSTRAP_FILE user-data.txt
    
    echo "Appending docker run command to the user-data.txt file ..."
    echo "su ec2-user -c \"docker run -d -p ${PORT}:3000 $CONTAINER_VOLUME --name ${CONTAINER_APP_NAME}-app-${CONTAINER_TAG} ${DOCKER_PROFILE}/${CONTAINER_APP_NAME}-app${CONTAINER_TAG}\"" >> user-data.txt
    echo "Initializing instance..."
    new_image_id=$($AWS $JSON_FMT ec2 run-instances --image-id  $AMI_ID --count 1 --instance-type t2.micro --key-name $KEY_PAIR --security-groups ohrs-default --user-data file://$(pwd)/user-data.txt --tag-specifications "[ { \"ResourceType\": \"instance\", \"Tags\": [ { \"Key\": \"Name\", \"Value\": \"${INSTANCE_NAME}\" } ] } ] " | grep InstanceId  | tr -d ' ",' | awk -F: '{print $2}')
    
    echo "Instance created, summary:"
    $AWS ec2 describe-instances --filters "Name=instance-id, Values=$new_image_id"
}

NO_COLOUR="\033[0m"
BOLD_RED="\033[1;49;91m"

function run_ec2_action {

   if [[ ${instance_public_ip[$target]} != "---" ]]; then
       ip_addr=${instance_public_ip[$target]}
   else
       ip_addr=${instance_private_ip[$target]}
   fi

   case $EC2_ACTION in
       SSH_INSTANCE )
           echo "ssh -Y -o \"StrictHostKeyChecking no\" -i $PEM_FILE $INSTANCE_USR@$ip_addr"
           ssh -Y -o "StrictHostKeyChecking no" -i $PEM_FILE $INSTANCE_USR@$ip_addr
           ;;  
       SR-CMD_INSTANCE )
           ssh -o "StrictHostKeyChecking no" -i $PEM_FILE $INSTANCE_USR@$ip_addr <<< "$SR_CMD"
           ;;  
       SCP_INSTANCE )
           scp  -o "StrictHostKeyChecking no" -i $PEM_FILE $LOCAL_FILE $INSTANCE_USR@$ip_addr:$REMOTE_FILE
           ;;  
       BROWSER_INSTANCE )
           eval $BROWSER http://$ip_addr:$PORT
           ;;  
       RUN_INSTANCE )
           run_instance
           ;;  
       START_INSTANCE )
           $AWS ec2 start-instances --instance-ids  ${instance_id[$target]} | jq
           #$AWS ec2 start-instances --instance-ids  ${instance_id[$target]} | pygmentize -l json  -f 256 -O style=monokai
           ;;  
       STOP_INSTANCE )
           $AWS ec2 stop-instances --instance-ids  ${instance_id[$target]} | jq
           #$AWS ec2 stop-instances --instance-ids  ${instance_id[$target]} | pygmentize -l json  -f 256 -O style=monokai
           ;;  
       TERMINATE_INSTANCE )
           echo
           printf "********************** (${BOLD_RED}ATENTION${NO_COLOUR}) **************************\n\n"
           printf "      You are about to ${BOLD_RED}\"TERMINATE\"${NO_COLOUR} this instance\n\n"
           printf "           ${BOLD_RED}THIS ACTION CAN NOT BE UNDONE!!\n\n${NO_COLOUR}"
           printf "***********************************************************\n\n${NO_COLOUR}"
           echo -n 'Type the exactly instance name to proceed: '
           read instance_name_to_delete
           if [[ $instance_name_to_delete == ${instance_name[$target]} ]]; then
               $AWS ec2 terminate-instances --instance-ids  ${instance_id[$target]}  | pygmentize -l json  -f 256 -O style=monokai
           else
               echo
               echo 'Instance name does not match, action canceled!'
           fi
           ;;  
        *   )   
           echo "Default action."
   esac
}
