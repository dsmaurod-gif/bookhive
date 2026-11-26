output "alb_dns_name" {
  description = "Direccion DNS del ALB"
  value       = aws_lb.sync.dns_name
}

output "alb_arn" {
  description = "ARN del ALB"
  value       = aws_lb.sync.arn
}

output "target_group_arn" {
  description = "ARN del grupo de destino"
  value       = aws_lb_target_group.sync.arn
}

output "asg_nombre" {
  description = "Nombre del grupo de Auto Scaling"
  value       = aws_autoscaling_group.sync.name
}

output "bucket_ansible" {
  description = "Bucket con los playbooks de Ansible"
  value       = aws_s3_bucket.ansible.id
}

output "alb_arn_suffix" {
  description = "Sufijo del ARN del ALB: es la dimensión LoadBalancer de las métricas de CloudWatch"
  value       = aws_lb.sync.arn_suffix
}

output "target_group_arn_suffix" {
  description = "Sufijo del ARN del grupo de destino: es la dimensión TargetGroup de las métricas de CloudWatch"
  value       = aws_lb_target_group.sync.arn_suffix
}