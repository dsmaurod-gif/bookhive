output "sns_topic_arn" {
  description = "ARN del tema SNS eventos-club"
  value       = aws_sns_topic.eventos_club.arn
}

output "sqs_queue_url" {
  description = "URL de la cola de correos"
  value       = aws_sqs_queue.correos.id
}

output "dlq_url" {
  description = "URL de la cola de mensajes fallidos"
  value       = aws_sqs_queue.dlq.id
}

output "dlq_arn" {
  description = "ARN de la cola de mensajes fallidos"
  value       = aws_sqs_queue.dlq.arn
}

output "sns_alertas_arn" {
  description = "ARN del tema SNS de alertas (destino de las alarmas de CloudWatch)"
  value       = aws_sns_topic.alertas.arn
}

output "notificador_nombre" {
  description = "Nombre de la Lambda notificador"
  value       = aws_lambda_function.notificador.function_name
}

output "dlq_nombre" {
  description = "Nombre de la cola de mensajes fallidos"
  value       = aws_sqs_queue.dlq.name
}