sudo mkdir -p /etc/ecs  
sudo touch /etc/ecs/ecs.config
sudo chmod -R +777 /etc/ecs
sudo echo "ECS_CLUSTER=MongoEcsCluster" >> /etc/ecs/ecs.config
curl -O https://s3.us-west-2.amazonaws.com/amazon-ecs-agent-us-west-2/amazon-ecs-init-latest.x86_64.rpm
sudo yum localinstall -y amazon-ecs-init-latest.x86_64.rpm
sudo yum install -y docker
sudo systemctl enable --now --no-block ecs
