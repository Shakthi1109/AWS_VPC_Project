#!/bin/bash

# VPC configuration
AWS_REGION="us-east-1"
VPC_IP="10.0.0.0/16"
PUB_SUB_ID="10.0.1.0/24"
PVT_SUB_ID="10.0.2.0/24"

# Create the VPC
response=$(aws ec2 create-vpc --cidr-block $VPC_IP --region $AWS_REGION)
# Extract VPC ID using jq and store it in a variable
vpc_id=$(echo $response | jq -r '.Vpc.VpcId')

aws ec2 create-tags --resources $vpc_id --tags Key=Name,Value=MyVPC --region $AWS_REGION
# Display the VPC ID
echo "VPC ID: $vpc_id"


# Create the Public Subnet
response1=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block $PUB_SUB_ID --region $AWS_REGION)
public_subnet_id=$(echo $response1 | jq -r '.Subnet.SubnetId')

aws ec2 create-tags --resources $public_subnet_id --tags Key=Name,Value=myPublicSubnet --region $AWS_REGION
echo "Public Subnet ID: $public_subnet_id"


# Create the Private Subnet
response3=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block $PVT_SUB_ID --region $AWS_REGION)
private_subnet_id=$(echo $response3 | jq -r '.Subnet.SubnetId')

aws ec2 create-tags --resources $private_subnet_id --tags Key=Name,Value=myPrivateSubnet --region $AWS_REGION
echo "Private Subnet ID: $private_subnet_id"


#Create Internet Gateway
response4=$(aws ec2 create-internet-gateway --region $AWS_REGION)
internet_gateway_id=$(echo $response4 | jq -r '.InternetGateway.InternetGatewayId')

aws ec2 create-tags --resources $internet_gateway_id --tags Key=Name,Value=myInternetGateway --region $AWS_REGION
echo "InternetGateway ID: $internet_gateway_id"

#Attach Internet Gateway
aws ec2 attach-internet-gateway --internet-gateway-id $internet_gateway_id --vpc-id $vpc_id --region $AWS_REGION
echo "Internet Gateway Attached to VPC"


#Create IP for NAT Gateway:
ipResponse=$(aws ec2 allocate-address --domain vpc --region $AWS_REGION)
ip_response_id=$(echo $ipResponse | jq -r '.AllocationId')

natGatewayResponse=$(aws ec2 create-nat-gateway --subnet-id $public_subnet_id --allocation-id $ip_response_id --region $AWS_REGION)
nat_gateway_id=$(echo $natGatewayResponse | jq -r '.NatGateway.NatGatewayId')

aws ec2 create-tags --resources $nat_gateway_id --tags Key=Name,Value=myPublicNATGateway --region $AWS_REGION


#Create Public Route Table
route_table_response=$(aws ec2 create-route-table --vpc-id $vpc_id --region $AWS_REGION)
route_table_id=$(echo $route_table_response | jq -r '.RouteTable.RouteTableId')

aws ec2 create-tags --resources $route_table_id --tags Key=Name,Value=PublicRouteTable --region $AWS_REGION
echo "Public Route Table ID: $route_table_id"


#Create Private Route Table
route_table_response2=$(aws ec2 create-route-table --vpc-id $vpc_id --region $AWS_REGION)
route_table_id2=$(echo $route_table_response2 | jq -r '.RouteTable.RouteTableId')

aws ec2 create-tags --resources $route_table_id2 --tags Key=Name,Value=PrivateRouteTable --region $AWS_REGION
echo "Private Route Table ID: $route_table_id2"


#Attach public route table to internet
echo "Create route:"
aws ec2 create-route --route-table-id $route_table_id --destination-cidr-block 0.0.0.0/0 --gateway-id $internet_gateway_id --region $AWS_REGION
aws ec2 create-route --route-table-id $route_table_id2 --destination-cidr-block 0.0.0.0/0 --gateway-id $nat_gateway_id --region $AWS_REGION

#Associate route table to public subnet
ass_response1=$(aws ec2 associate-route-table --route-table-id $route_table_id --subnet-id $public_subnet_id --region $AWS_REGION)
rt_table_association_public_id=$(echo $ass_response1 | jq -r '.AssociationId')
echo "Route table association public ID: $rt_table_association_public_id"


#Associate route table to pvt subnet
ass_response2=$(aws ec2 associate-route-table --route-table-id $route_table_id2 --subnet-id $private_subnet_id --region $AWS_REGION)
rt_table_association_pvt_id=$(echo $ass_response2 | jq -r '.AssociationId')
echo "Route table association private ID: $rt_table_association_pvt_id"


#Create WEB Security Group:

security_group_response=$(aws ec2 create-security-group --group-name WebSecurityGroup --description "WEB security group" --vpc-id $vpc_id --region $AWS_REGION)
sec_grp_id1=$(echo $security_group_response | jq -r '.GroupId')

aws ec2 create-tags --resources $sec_grp_id1 --tags Key=Name,Value=myWebSecurityGroup --region $AWS_REGION
echo "Web Security Group ID: $sec_grp_id1"


security_group_response2=$(aws ec2 create-security-group --group-name DBSecurityGroup --description "DB security group" --vpc-id $vpc_id --region $AWS_REGION)
security_group_id2=$(echo $security_group_response2 | jq -r '.GroupId')

aws ec2 create-tags --resources $security_group_id2 --tags Key=Name,Value=myDBSecurityGroup --region $AWS_REGION
echo "DB Security Group ID: $security_group_id2"

echo "authorize security group"
aws ec2 authorize-security-group-ingress --group-id $sec_grp_id1 --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $AWS_REGION
echo "authorize security group"
aws ec2 authorize-security-group-ingress --group-id $sec_grp_id1 --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $AWS_REGION

#Create Key Pair
ssh-keygen -t rsa -b 2048 -f ~/.ssh/cli-keyPair
aws ec2 import-key-pair --key-name cli-keyPair --public-key-material fileb://~/.ssh/cli-keyPair.pub > /dev/null

echo "Creating an instance for web server"
web_instance_id=$(aws ec2 run-instances --image-id ami-0fc5d935ebf8bc3bc --instance-type t2.micro --count 1 --subnet-id $public_subnet_id --security-group-ids $sec_grp_id1 --associate-public-ip-address --key-name cli-keyPair --query 'Instances[0].InstanceId' --output text)

echo "Waiting for instance $web_instance_id to be created and launched"
while true; do

	web_status=`aws ec2 describe-instance-status --instance-ids $web_instance_id --query 'InstanceStatuses[0].InstanceState.Name' --output text`
    echo "Web status: $web_status"

    if [ "$web_status" == "running" ]; then
        sleep 20

		web_ip=`aws ec2 describe-instances --instance-ids $web_instance_id --query "Reservations[0].Instances[0].PublicIpAddress" | grep -Eo "[0-9.]+"`
        echo "Web IP: $web_ip"

        scp -i ~/.ssh/cli-keyPair server.sh ubuntu@$web_ip:~/
        ssh -i ~/.ssh/cli-keyPair ubuntu@$web_ip 'bash -s' < server.sh

        echo "Web IP: $web_ip"
        sleep 3
        break
	fi
	sleep 10
done