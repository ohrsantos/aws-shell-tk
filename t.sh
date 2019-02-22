echo "$(echo $instances | jq '.Reservations[].Instances[].InstanceId')|$(echo $instances | jq '.Reservations[].Instances[].InstanceType')"
