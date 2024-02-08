terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.34.0"
    }
  }
}

# provider block
provider "aws" {
  region = "us-east-1"
  # access_key = var.accesskey
  # secret_key = var.secretkey
}

module "asg" {
  source              = "../modules/asg"
  az_names            = ["us-east-1a", "us-east-1b"]
  vpc_cidr            = "172.16.0.0/16"
  public_subnet_cidr  = ["172.16.1.0/24", "172.16.2.0/24"] # You can change as per required subnet cidr
  private_subnet_cidr = ["172.16.11.0/24", "172.16.12.0/24"] # Change as per required subnet cidr
  ami                 = "ami-006dcf34c09e50022" # you can change as per your custom ami
  instance_type       = "t2.micro" 
  key_name            = "aws-deep-keypair" # add your keypair required to access instances
  min_size            = 1 # Minimum instance running
  desired_capacity    = 2 # Should not be less than min_size
  max_size            = 5 # Max instances required for scale-up

}
