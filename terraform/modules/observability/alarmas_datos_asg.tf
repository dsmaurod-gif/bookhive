# Alarmas de limitación (throttling) de DynamoDB: una de lectura y otra de escritura.
# La tabla usa PAY_PER_REQUEST, por eso el throttling solo aparece ante picos muy bruscos.
resource "aws_cloudwatch_metric_alarm" "dynamodb_throttling" {
  for_each = {
    lectura   = "ReadThrottleEvents"
    escritura = "WriteThrottleEvents"
  }

  alarm_name          = "${local.prefijo}-dynamodb-${each.key}-throttling"
  alarm_description   = "DynamoDB limitó peticiones de ${each.key} en los últimos 5 minutos"
  namespace           = "AWS/DynamoDB"
  metric_name         = each.value
  dimensions          = { TableName = var.tabla_notas_nombre }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_alertas_arn]
  ok_actions          = [var.sns_alertas_arn]
}

# CPU del grupo de Auto Scaling por encima del 80 % durante 5 minutos (RNF-28)
resource "aws_cloudwatch_metric_alarm" "asg_cpu_alta" {
  alarm_name          = "${local.prefijo}-asg-cpu-alta"
  alarm_description   = "El uso promedio de CPU de EC2 Sync superó el 80 % durante 5 minutos"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  dimensions          = { AutoScalingGroupName = var.asg_nombre }
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_alertas_arn]
  ok_actions          = [var.sns_alertas_arn]
}