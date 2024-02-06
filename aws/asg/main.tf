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
}

module "asg" {
  source              = "../modules/asg"
  az_names            = ["us-east-1a", "us-east-1b"]
  vpc_cidr            = "172.16.0.0/16"
  public_subnet_cidr  = ["172.16.0.0/24", "172.16.1.0/24"]
  private_subnet_cidr = ["172.16.10.0/24", "172.16.11.0/24"]
  ami                 = "ami-006dcf34c09e50022"
  instance_type       = "t2.micro"
  min_size            = 1
  desired_capacity    = 2
  max_size            = 5


}
