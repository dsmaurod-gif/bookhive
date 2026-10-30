output "tabla_notas_nombre" {
  description = "Nombre de la tabla DynamoDB de notas y resaltados"
  value       = aws_dynamodb_table.notas.name
}

output "tabla_notas_arn" {
  description = "ARN de la tabla DynamoDB"
  value       = aws_dynamodb_table.notas.arn
}

output "bucket_app" {
  description = "Bucket S3 de la app web, libros y portadas"
  value       = aws_s3_bucket.app.id
}

output "secreto_arn" {
  description = "ARN del secreto con las credenciales de la base"
  value       = aws_secretsmanager_secret.db.arn
}

output "aurora_arn" {
  description = "ARN del clúster Aurora (vacío si está deshabilitado)"
  value       = var.habilitar_aurora ? aws_rds_cluster.aurora[0].arn : ""
}

output "aurora_endpoint" {
  description = "Endpoint de escritura de Aurora (vacío si está deshabilitado)"
  value       = var.habilitar_aurora ? aws_rds_cluster.aurora[0].endpoint : ""
}

output "cache_endpoint_primario" {
  description = "Endpoint del primario de ElastiCache (vacío si está deshabilitado)"
  value       = var.habilitar_cache ? aws_elasticache_replication_group.cache[0].primary_endpoint_address : ""
}