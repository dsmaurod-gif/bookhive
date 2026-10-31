locals {
  prefijo = "${var.proyecto}-${var.entorno}"
}

# 1. SNS: tema eventos-club. Una entrada (la Lambda de la API) y varias salidas (hoy solo la cola SQS).
#    El "suscriptor futuro" del diagrama (ej. notificaciones push) se agregaría con otro
#    aws_sns_topic_subscription, sin tocar la Lambda que publica.
resource "aws_sns_topic" "eventos_club" {
  name = "${local.prefijo}-eventos-club"
}

# 2. SQS: cola de correos y su cola de mensajes fallidos (DLQ)
resource "aws_sqs_queue" "dlq" {
  name                      = "${local.prefijo}-correos-dlq"
  message_retention_seconds = 1209600 # 14 días (RNF-07)
  sqs_managed_sse_enabled   = true
}

resource "aws_sqs_queue" "correos" {
  name                       = "${local.prefijo}-correos"
  visibility_timeout_seconds = 60 # mayor que el tiempo máximo de la Lambda notificador
  sqs_managed_sse_enabled    = true

  # Tras 3 intentos fallidos el mensaje pasa a la DLQ
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}

# Permiso para que SNS pueda escribir en la cola (solo desde nuestro tema)
data "aws_iam_policy_document" "sns_a_sqs" {
  statement {
    sid       = "PermitirSoloNuestroTema"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.correos.arn]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.eventos_club.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "correos" {
  queue_url = aws_sqs_queue.correos.id
  policy    = data.aws_iam_policy_document.sns_a_sqs.json
}

# 3. Suscripción: SNS -> SQS
resource "aws_sns_topic_subscription" "correos" {
  topic_arn            = aws_sns_topic.eventos_club.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.correos.arn
  raw_message_delivery = true # entrega el mensaje tal cual, sin el sobre de SNS
}

# 4. SES: identidad (correo) desde la que se envía. En sandbox hay que verificarla con el enlace que llega al correo.
resource "aws_sesv2_email_identity" "demo" {
  email_identity = var.correo_demo
}

# 5. Lambda notificador: lee la cola y pide a SES que envíe el correo (va fuera de la VPC, como en el diagrama)
data "archive_file" "notificador" {
  type        = "zip"
  source_file = "${path.module}/lambda_src/notificador.py"
  output_path = "${path.module}/notificador.zip"
}

resource "aws_cloudwatch_log_group" "notificador" {
  name              = "/aws/lambda/${local.prefijo}-notificador"
  retention_in_days = 30 # RNF-29
}

data "aws_iam_policy_document" "lambda_confianza" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "notificador" {
  name               = "${local.prefijo}-notificador-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_confianza.json
}

# Política administrada: leer/borrar mensajes de SQS y escribir logs
resource "aws_iam_role_policy_attachment" "notificador_sqs" {
  role       = aws_iam_role.notificador.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_iam_role_policy" "notificador_ses" {
  name = "${local.prefijo}-notificador-ses"
  role = aws_iam_role.notificador.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ses:SendEmail"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "notificador" {
  function_name    = "${local.prefijo}-notificador"
  role             = aws_iam_role.notificador.arn
  runtime          = "python3.12"
  handler          = "notificador.handler"
  filename         = data.archive_file.notificador.output_path
  source_code_hash = data.archive_file.notificador.output_base64sha256
  timeout          = 10
  memory_size      = 128

  environment {
    variables = {
      REMITENTE    = var.correo_demo
      DESTINATARIO = var.correo_demo
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.notificador,
    aws_iam_role_policy_attachment.notificador_sqs,
  ]
}

# La cola dispara la Lambda
resource "aws_lambda_event_source_mapping" "correos" {
  event_source_arn = aws_sqs_queue.correos.arn
  function_name    = aws_lambda_function.notificador.arn
  batch_size       = 1
}

# 6. Alarma: avisa si llega algún mensaje a la DLQ (CloudWatch)
resource "aws_cloudwatch_metric_alarm" "dlq" {
  alarm_name          = "${local.prefijo}-dlq-con-mensajes"
  alarm_description   = "Hay correos que fallaron 3 veces y esperan revisión manual"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  dimensions          = { QueueName = aws_sqs_queue.dlq.name }
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
}