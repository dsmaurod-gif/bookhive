output "api_url" {
  description = "URL base de la API (agregar /clubes)"
  value       = aws_api_gateway_stage.api.invoke_url
}

output "lambda_nombre" {
  description = "Nombre de la Lambda API de clubes"
  value       = aws_lambda_function.api_clubes.function_name
}