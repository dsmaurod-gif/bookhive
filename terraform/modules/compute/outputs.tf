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
