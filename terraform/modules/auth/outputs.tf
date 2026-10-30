
output "user_pool_id" {
  description = "ID del user pool"
  value       = aws_cognito_user_pool.lectores.id
}

output "user_pool_arn" {
  description = "ARN del user pool (lo usa el autorizador de API Gateway)"
  value       = aws_cognito_user_pool.lectores.arn
}

output "user_pool_client_id" {
  description = "ID del client de la aplicación"
  value       = aws_cognito_user_pool_client.web.id
}
