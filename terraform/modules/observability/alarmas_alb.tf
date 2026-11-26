resource "aws_cloudwatch_metric_alarm" "alb_hosts_no_saludables" {
  alarm_name          = "${local.prefijo}-alb-hosts-no-saludables"
  alarm_description   = "El ALB reporta instancias EC2 Sync no saludables durante 5 minutos seguidos"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  dimensions          = local.dimensiones_alb
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 5
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_alertas_arn]
  ok_actions          = [var.sns_alertas_arn]
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${local.prefijo}-alb-5xx-porcentaje"
  alarm_description   = "Más del 1 % de las peticiones terminó en error 5xx durante 5 minutos"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 1
  evaluation_periods  = 5
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_alertas_arn]
  ok_actions          = [var.sns_alertas_arn]

  metric_query {
    id          = "porcentaje"
    expression  = "100 * FILL(errores, 0) / FILL(solicitudes, 1)"
    label       = "Porcentaje de errores 5xx"
    return_data = true
  }

  metric_query {
    id = "errores"

    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_Target_5XX_Count"
      dimensions  = local.dimensiones_alb
      period      = 60
      stat        = "Sum"
    }
  }

  metric_query {
    id = "solicitudes"

    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "RequestCount"
      dimensions  = local.dimensiones_alb
      period      = 60
      stat        = "Sum"
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_latencia" {
  alarm_name          = "${local.prefijo}-alb-latencia"
  alarm_description   = "El tiempo de respuesta promedio de EC2 Sync superó 2 segundos durante 5 minutos"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  dimensions          = local.dimensiones_alb
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  threshold           = 2
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_alertas_arn]
  ok_actions          = [var.sns_alertas_arn]
}