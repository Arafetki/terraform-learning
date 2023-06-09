provider "aws" {

    region = "eu-west-3"
  
}

/*

    Terraform Lab :1

    1- Create custom vpc
    2- Create custom subnet
    3- Create Route table & Internet gateway
    4- Provision ec2 instance
    5- Deploy nginx docker container
    6- Create SG ( open port 22 & port 8080 )


 */

# Defining env variables

variable "vpc_cidr" {

    description = "Vpc's cidr range"
    type = string
  
}

variable "subnet1_cidr" {

    description = "Subnet1's cidr range"
    type = string
  
}

variable "avail_zone" {
    type = string
}

variable "my_ip" {
  type = string

}

variable "instance_type" {
    type = string
}

variable "pub_key" {
    type = string
}


# Create Vpc

resource "aws_vpc" "demo_vpc" {

    cidr_block = var.vpc_cidr

    tags = {
        
        Name = "demo_vpc"
    }
  
}

# Create Igw

resource "aws_internet_gateway" "demo_igw" {
  
    vpc_id = aws_vpc.demo_vpc.id

    tags={

        Name = "demo_igw"
        
    }
}

# Create Subnet1

resource "aws_subnet" "demo_subnet1" {

    vpc_id = aws_vpc.demo_vpc.id

    cidr_block = var.subnet1_cidr

    availability_zone = var.avail_zone

    map_public_ip_on_launch = true

    tags = {
      
         Name = "demo_subnet1" 

    }
  
}


# Create Route Table for demo_subnet1 in demo_vpc

resource "aws_route_table" "demo_rt1" {

    vpc_id = aws_vpc.demo_vpc.id
    
    route {

        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.demo_igw.id
    }

    tags = {
      Name = "demo_rt1"
    }
  
}

# Create subnet association for demo_rt1 to subnet1 

resource "aws_route_table_association" "demo_association_rt1_subnet1" {

    subnet_id = aws_subnet.demo_subnet1.id
    route_table_id = aws_route_table.demo_rt1.id
  
}

# Create SG ( open port 22 & port 8080)

resource "aws_security_group" "demo_remoteAccess_sg" {
    name = "demo_remoteAccess_sg"
    description = "Allow SSH connection from my ip & HTTP traffic from anywhere"
    vpc_id = aws_vpc.demo_vpc.id

    ingress {
        description = "Allow SSH from my ip"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip]

    }

    ingress {
        description = "Allow HTTP traffic from anywhere"
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]

    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }

    tags = {
      Name = "demo_remoteAccess_sg"
    }
}

# Fetch amazon machine image

data "aws_ami" "demo_latest_amazon_linux_image" {

    most_recent = true
    owners = ["amazon"]

    filter {
      name = "name"
      values = ["amzn2-ami-kernel-*-x86_64-gp2"]
    }

}


# Output the result of the query

output "ec2_demo_myapp_pub_ip" {

    value = aws_instance.demo_myapp.public_ip
  
}


# Create SSH  keyPair

resource "aws_key_pair" "ssh-key" {
  key_name = "demo_key_pair"
  public_key = var.pub_key
}


# Create EC2 instance

resource "aws_instance" "demo_myapp" {
    subnet_id = aws_subnet.demo_subnet1.id
    ami = data.aws_ami.demo_latest_amazon_linux_image.id
    instance_type = var.instance_type

    vpc_security_group_ids = [aws_security_group.demo_remoteAccess_sg.id]
    availability_zone = var.avail_zone

    key_name = aws_key_pair.ssh-key.key_name

    user_data = <<EOF

                #!/bin/bash
                sudo yum -y update && sudo yum install  -y docker
                sudo systemctl start docker
                sudo systemctl enable docker
                sudo usermod -aG docker ec2-user
                docker run -d -p 8080:80 nginx
                
                EOF

    tags = {
      Name = "demo_myapp"
    }
}