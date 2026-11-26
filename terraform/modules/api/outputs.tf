output "api_url" {
  description = "URL base de la API (agregar /clubes)"
  value       = aws_api_gateway_stage.api.invoke_url
}

output "lambda_nombre" {
  description = "Nombre de la Lambda API de clubes"
  value       = aws_lambda_function.api_clubes.function_name
}

output "api_nombre" {
  description = "Nombre de la API REST (dimensión ApiName de las métricas de CloudWatch)"
  value       = aws_api_gateway_rest_api.api.name
}

output "stage_nombre" {
  description = "Nombre del stage de la API (dimensión Stage de las métricas de CloudWatch)"
  value       = aws_api_gateway_stage.api.stage_name
}