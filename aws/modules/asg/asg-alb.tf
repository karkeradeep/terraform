##### Launch Template and ASG Resources #####
resource "aws_launch_template" "launch_template" {
  name          = local.launch_template_name
  image_id      = var.ami
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interfaces {
    device_index                = 0
    associate_public_ip_address = "true" # Set to false to disable Public IP assignment since the instances are behind a loadbalancer.
    security_groups             = [aws_security_group.asg_security_group.id]
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
  health_check_grace_period = 300
  force_delete              = true
  vpc_zone_identifier       = [for i in aws_subnet.public_subnet[*] : i.id] #[for i in aws_subnet.private_subnet[*] : i.id]
  target_group_arns         = [aws_lb_target_group.target_group.arn]

  # instance_maintenance_policy {
  #   min_healthy_percentage = 90
  #   max_healthy_percentage = 120
  # }

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
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Add Public Static IP to allow access by certain IP.
  }

  ingress {
    description     = "HTTP"
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
# Scale IN / OUT Policies
#################################
resource "aws_autoscaling_policy" "web_policy_up" {
  name                   = "web_policy_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.auto_scaling_group.name
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_up" {
  alarm_name          = "web_cpu_alarm_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "60"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.auto_scaling_group.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions     = [aws_autoscaling_policy.web_policy_up.arn]
}

resource "aws_autoscaling_policy" "web_policy_down" {
  name                   = "web_policy_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.auto_scaling_group.name
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_down" {
  alarm_name          = "web_cpu_alarm_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "5"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.auto_scaling_group.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions     = [aws_autoscaling_policy.web_policy_down.arn]
}
################ Scheduled scale in/out ################
# scale out - during business hour
resource "aws_autoscaling_schedule" "scale_out_business_hours" {
  scheduled_action_name = "scale-out-during-business-hours"
  min_size              = 2
  max_size              = 10
  desired_capacity      = 5
  recurrence            = "00 11 * * *"
  time_zone             = "Asia/Kolkata"

  autoscaling_group_name = aws_autoscaling_group.auto_scaling_group.name
}

# scale in - night
resource "aws_autoscaling_schedule" "scale_in_at_night" {
  scheduled_action_name = "scale-in-after-business-hours"
  min_size              = 1
  max_size              = 5
  desired_capacity      = 1
  recurrence            = "00 13 * * *"
  time_zone             = "Asia/Kolkata"

  autoscaling_group_name = aws_autoscaling_group.auto_scaling_group.name
}
