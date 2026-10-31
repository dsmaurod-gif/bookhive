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