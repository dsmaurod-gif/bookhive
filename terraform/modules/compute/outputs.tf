
output "alb_dns_name" {
  description = "DNS público del balanceador"
  value       = aws_lb.principal.dns_name
}

output "alb_arn" {
  description = "ARN del Application Load Balancer"
  value       = aws_lb.principal.arn
}

output "target_group_arn" {
  description = "ARN del grupo de destino"
  value       = aws_lb_target_group.app.arn
}

output "asg_name" {
  description = "Nombre del Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "launch_template_id" {
  description = "Identificador del Launch Template"
  value       = aws_launch_template.app.id
}
