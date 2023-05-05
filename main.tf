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
    6- Create SG ( open port 22 & port 80 )


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

resource "aws_route_table_association" "demo_association_rt1_subnet1" {

    subnet_id = aws_subnet.demo_subnet1.id
    route_table_id = aws_route_table.demo_rt1.id
  
}