resource "aws_sns_topic" "alertas" {
  name = "${local.prefijo}-alertas"
}

resource "aws_sns_topic_subscription" "alertas_correo" {
  topic_arn = aws_sns_topic.alertas.arn
  protocol  = "email"
  endpoint  = var.correo_alertas
}