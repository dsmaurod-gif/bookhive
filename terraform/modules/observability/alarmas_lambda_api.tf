locals {
  # Funciones Lambda vigiladas. La clave forma parte del nombre de cada alarma.
  lambdas = {
    "api-clubes"  = var.lambda_api_nombre
    "notificador" = var.lambda_notificador_nombre
  }
}

# Alarma 1 (una por función): la Lambda devolvió errores en los últimos 5 minutos
resource "aws_cloudwatch_metric_alarm" "lambda_errores" {
  for_each = local.lambdas

  alarm_name          = "${local.prefijo}-lambda-${each.key}-errores"
  alarm_description   = "La función ${each.value} devolvió errores en los últimos 5 minutos"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  dimensions          = { FunctionName = each.value }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_alertas_arn]
  ok_actions          = [var.sns_alertas_arn]
}

# Alarma 2: la Lambda de la API fue limitada por exceso de peticiones simultáneas
resource "aws_cloudwatch_metric_alarm" "lambda_api_throttles" {
  alarm_name          = "${local.prefijo}-lambda-api-clubes-throttles"
  alarm_description   = "La Lambda de la API fue limitada (throttling) en los últimos 5 minutos"
  namespace           = "AWS/Lambda"
  metric_name         = "Throttles"
  dimensions          = { FunctionName = var.lambda_api_nombre }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_alertas_arn]
  ok_actions          = [var.sns_alertas_arn]
}

# Alarma 3: más del 1 % de las llamadas a la API terminó en error 5xx (RNF-28)
resource "aws_cloudwatch_metric_alarm" "apigw_5xx" {
  alarm_name          = "${local.prefijo}-apigw-5xx-porcentaje"
  alarm_description   = "Más del 1 % de las llamadas a la API terminó en error 5xx durante 5 minutos"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 1
  evaluation_periods  = 5
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_alertas_arn]
  ok_actions          = [var.sns_alertas_arn]

  metric_query {
    id          = "porcentaje"
    expression  = "100 * FILL(errores, 0) / FILL(llamadas, 1)"
    label       = "Porcentaje de errores 5xx"
    return_data = true
  }

  metric_query {
    id = "errores"

    metric {
      namespace   = "AWS/ApiGateway"
      metric_name = "5XXError"
      dimensions  = { ApiName = var.api_nombre, Stage = var.api_stage }
      period      = 60
      stat        = "Sum"
    }
  }

  metric_query {
    id = "llamadas"

    metric {
      namespace   = "AWS/ApiGateway"
      metric_name = "Count"
      dimensions  = { ApiName = var.api_nombre, Stage = var.api_stage }
      period      = 60
      stat        = "Sum"
    }
  }
}

# Alarma 4: la latencia promedio de la API supera 2 segundos (RNF-16). API Gateway la mide en milisegundos.
resource "aws_cloudwatch_metric_alarm" "apigw_latencia" {
  alarm_name          = "${local.prefijo}-apigw-latencia"
  alarm_description   = "La latencia promedio de la API superó 2 segundos durante 5 minutos"
  namespace           = "AWS/ApiGateway"
  metric_name         = "Latency"
  dimensions          = { ApiName = var.api_nombre, Stage = var.api_stage }
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  threshold           = 2000
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_alertas_arn]
  ok_actions          = [var.sns_alertas_arn]
}