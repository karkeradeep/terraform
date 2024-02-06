
##### Launch Template and ASG Resources #####
resource "aws_launch_template" "launch_template" {
  name          = local.launch_template_name
  image_id      = var.ami
  instance_type = var.instance_type

  network_interfaces {
    device_index    = 0
    security_groups = [aws_security_group.asg_security_group.id]
  }
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = local.launch_template_ec2_name
    }
  }

  user_data = filebase64("${path.module}/install-apache.sh")
}
###### AWS Autoscaling Group #########
resource "aws_autoscaling_group" "auto_scaling_group" {
  desired_capacity          = var.desired_capacity
  max_size                  = var.max_size
  min_size                  = var.min_size
  termination_policies      = ["OldestInstance"]
  health_check_type         = "ELB"
  health_check_grace_period = 120
  vpc_zone_identifier       = [for i in aws_subnet.private_subnet[*] : i.id]
  target_group_arns         = [aws_lb_target_group.target_group.arn]

  lifecycle {
    create_before_destroy = true
  }

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = aws_launch_template.launch_template.latest_version
  }

}
###### ALB Security Group #########
resource "aws_security_group" "alb_security_group" {
  name        = local.alb_security_group_name
  description = "ALB Security Group"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = local.alb_security_group_name
  }
}
##### ASG Security Group ######
resource "aws_security_group" "asg_security_group" {
  name        = local.asg_security_group_name
  description = "ASG Security Group"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = local.asg_security_group_name
  }
}

##### Application Load Balancer Resources ######
resource "aws_lb" "alb" {
  name               = local.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_security_group.id]
  subnets            = [for i in aws_subnet.public_subnet : i.id]
}

resource "aws_lb_target_group" "target_group" {
  name     = local.target_group_name
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  health_check {
    path    = "/"
    matcher = 200
  }
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}
#################################


