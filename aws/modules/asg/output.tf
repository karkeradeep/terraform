output "alb_public_url" {
  description = "Public URL"
  value       = aws_lb.alb.dns_name
}

output "asg_name" {
  value       = aws_autoscaling_group.auto_scaling_group.name
  description = "The name of the Auto Scaling Group"
}
