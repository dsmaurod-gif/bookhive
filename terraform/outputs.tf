output "tabla_notas" {
  description = "Nombre de la tabla DynamoDB de notas y resaltados"
  value       = module.data.tabla_notas_nombre
}

output "api_url" {
  description = "URL base de la API (agregar /clubes)"
  value       = module.api.api_url
}

output "sns_topic_arn" {
  description = "ARN del tema SNS eventos-club"
  value       = module.messaging.sns_topic_arn
}

output "dlq_url" {
  description = "URL de la cola de mensajes fallidos"
  value       = module.messaging.dlq_url
}

output "alb_dns_name" {
  description = "Direccion del ALB: probar con http://<valor>/ y http://<valor>/health"
  value       = module.compute.alb_dns_name
}

output "user_pool_id" {
  description = "ID del user pool de Cognito"
  value       = module.auth.user_pool_id
}

output "user_pool_client_id" {
  description = "ID del cliente de Cognito (para iniciar sesion por CLI)"
  value       = module.auth.user_pool_client_id
}

output "bucket_ansible" {
  description = "Bucket S3 con los archivos de Ansible"
  value       = module.compute.bucket_ansible
}

output "sns_alertas_arn" {
  description = "ARN del tema SNS de alertas (destino de las alarmas de CloudWatch)"
  value       = module.messaging.sns_alertas_arn
}

output "panel_nombre" {
  description = "Nombre del panel de CloudWatch"
  value       = module.observability.panel_nombre
}

output "cloudfront_dominio" {
  description = "Dominio de CloudFront: la entrada pública de BookHive"
  value       = module.edge.cloudfront_dominio
}