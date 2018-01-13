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

function run_instance {
    echo "Creating user-data.txt file ..."
    cp -f $BOOTSTRAP_FILE user-data.txt
    
    echo "Appending docker run command to the user-data.txt file ..."
    echo "su ec2-user -c \"docker run -d -p ${PORT}:3000 --name ${CONTAINER_APP_NAME}-app-${CONTAINER_TAG} ${DOCKER_PROFILE}/${CONTAINER_APP_NAME}-app:${CONTAINER_TAG}\"" >> user-data.txt
    
    echo "Initializing instance..."
    new_image_id=$($AWS $JSON_FMT ec2 run-instances --image-id  $AMI_ID --count 1 --instance-type t2.micro --key-name $KEY_PAIR --security-groups ohrs-default --user-data file://$(pwd)/user-data.txt | grep InstanceId  | tr -d ' ",' | awk -F: '{print $2}')
    
    echo "Instance created, summary:"
    $AWS ec2 describe-instances --filters "Name=instance-id, Values=$new_image_id"
}

function run_ec2_action {

   case $EC2_ACTION in
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
