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