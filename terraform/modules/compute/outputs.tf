output "alb_dns_name" {
  value       = aws_lb.sync.dns_name
  description = "Nombre DNS publico del Load Balancer"
}

output "alb_arn" {
  value       = aws_lb.sync.arn
  description = "ARN del Load Balancer"
}

output "target_group_arn" {
  value       = aws_lb_target_group.sync.arn
  description = "ARN del Target Group"
}

output "asg_name" {
  value       = aws_autoscaling_group.sync.name
  description = "Nombre del Auto Scaling Group"
}

output "launch_template_id" {
  value       = aws_launch_template.sync.id
  description = "ID del Launch Template"
}
