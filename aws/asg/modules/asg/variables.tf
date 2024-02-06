# Terraform Variables

# ##### AWS Region #####
# variable "aws_region" {
#   description = "Region in which AWS Resources to be created"
#   type        = string
# }

##### Local Values #####
locals {
  vpc_name                 = "demo-vnet"
  internet_gateway_name    = "demo-internet-gateway"
  public_subnet_name       = "demo-public-subnet"
  private_subnet_name      = "demo-private-subnet"
  public_route_table_name  = "demo-public-route-table"
  private_route_table_name = "demo-private-route-table"
  elastic_ip_name          = "demo-nat-elastic-ip"
  nat_gateway_name         = "demo-nat-gateway"
  alb_security_group_name  = "demo-alb-security-group"
  asg_security_group_name  = "demo-asg-security-group"
  launch_template_name     = "demo-launch-template"
  launch_template_ec2_name = "demo-asg-ec2"
  alb_name                 = "demo-external-alb"
  target_group_name        = "demo-alb-target-group"
}

##### VPC Variables #####
variable "vpc_cidr" {
  description = "VPC cidr block"
  type        = string
  #default     = "172.16.0.0/16"
}

variable "az_names" {
  type = list(string)
  #default = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidr" {
  description = "Public Subnet cidr block"
  type        = list(string)
  #default     = ["172.16.0.0/24", "172.16.1.0/24"]
}

variable "private_subnet_cidr" {
  description = "Private Subnet cidr block"
  type        = list(string)
  #default     = ["172.16.10.0/24", "172.16.11.0/24"]
}

##### Launch Template and ASG Variables #####
variable "ami" {
  description = "ami id"
  type        = string
}

variable "instance_type" {
  description = "The type of EC2 Instances to run (e.g. t2.micro)"
  type        = string
}

variable "min_size" {
  description = "The minimum number of EC2 Instances in the ASG"
  type        = number
}

variable "max_size" {
  description = "The maximum number of EC2 Instances in the ASG"
  type        = number
}

variable "desired_capacity" {
  description = "The desired number of EC2 Instances in the ASG"
  type        = number
}

