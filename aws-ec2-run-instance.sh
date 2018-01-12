app="container-b"
ver="1"
port="3332"

echo "Creating user-data.txt file ..."
cp -f user-data.template.txt user-data.txt

echo "Appending docker run command to the user-data.txt file ..."
echo "su ec2-user -c \"docker run -d -p ${PORT}:3000 --name ${CONTAINER_APP_NAME}-app-${CONTAINER_TAG} ${DOCKER_PROFILE}/${CONTAINER_APP_NAME}-app:${CONTAINER_TAG}\"" >> user-data.txt

echo "Initializing instance..."
new_image_id=$($AWS $JSON_FMT ec2 run-instances --image-id  ami-bd87c1d1 --count 1 --instance-type t2.micro --key-name ohrs-aws-sp-br --security-groups ohrs-default --user-data file://$(pwd)/user-data.txt | grep InstanceId  | tr -d ' ",' | awk -F: '{print $2}')

echo "Instance created, summary:"
$AWS ec2 describe-instances --filters "Name=instance-id, Values=$new_image_id"
