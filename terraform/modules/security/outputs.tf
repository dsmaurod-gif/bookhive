output "sg_alb_id" {
  description = "Grupo de seguridad del ALB"
  value       = aws_security_group.alb.id
}

output "sg_app_id" {
  description = "Grupo de seguridad de EC2 Sync"
  value       = aws_security_group.app.id
}

output "sg_cache_id" {
  description = "Grupo de seguridad de ElastiCache"
  value       = aws_security_group.cache.id
}

output "sg_db_id" {
  description = "Grupo de seguridad de Aurora"
  value       = aws_security_group.db.id
}

output "sg_lambda_id" {
  description = "Grupo de seguridad de las Lambda de la API"
  value       = aws_security_group.lambda.id
}