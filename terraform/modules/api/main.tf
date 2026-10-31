locals {
  prefijo = "${var.proyecto}-${var.entorno}"
}

# ---------- 1. Lambda "API de clubes" (dentro de la VPC, en las subredes de ambas AZ) ----------
data "archive_file" "api_clubes" {
  type        = "zip"
  source_file = "${path.module}/lambda_src/api_clubes.py"
  output_path = "${path.module}/api_clubes.zip"
}

resource "aws_cloudwatch_log_group" "api_clubes" {
  name              = "/aws/lambda/${local.prefijo}-api-clubes"
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

resource "aws_iam_role" "api_clubes" {
  name               = "${local.prefijo}-api-clubes-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_confianza.json
}

# Política administrada: escribir logs y crear las interfaces de red para correr dentro de la VPC
resource "aws_iam_role_policy_attachment" "api_clubes_vpc" {
  role       = aws_iam_role.api_clubes.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "api_clubes" {
  name = "${local.prefijo}-api-clubes-politica"
  role = aws_iam_role.api_clubes.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "PublicarEventos"
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = var.sns_topic_arn
      },
      {
        Sid      = "LeerCredenciales"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = var.secreto_arn
      }
    ]
  })
}

resource "aws_lambda_function" "api_clubes" {
  function_name    = "${local.prefijo}-api-clubes"
  role             = aws_iam_role.api_clubes.arn
  runtime          = "python3.12"
  handler          = "api_clubes.handler"
  filename         = data.archive_file.api_clubes.output_path
  source_code_hash = data.archive_file.api_clubes.output_base64sha256
  timeout          = 10
  memory_size      = 128
  publish          = true # crea una versión numerada en cada cambio de código

  # En el diagrama se dibuja una Lambda por AZ: en AWS es UNA función que corre en las subredes de ambas AZ.
  vpc_config {
    subnet_ids         = var.subredes_aplicacion
    security_group_ids = [var.sg_lambda_id]
  }

  environment {
    variables = {
      TOPIC_ARN  = var.sns_topic_arn
      SECRET_ARN = var.secreto_arn
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.api_clubes,
    aws_iam_role_policy_attachment.api_clubes_vpc,
  ]
}

# Alias "live": API Gateway llama al alias, no a la versión. Así se puede repartir tráfico entre versiones.
resource "aws_lambda_alias" "live" {
  name             = "live"
  function_name    = aws_lambda_function.api_clubes.function_name
  function_version = aws_lambda_function.api_clubes.version

  # Despliegue gradual (ejemplo): enviar el 10 % del tráfico a la versión 2
  # routing_config {
  #   additional_version_weights = { "2" = 0.1 }
  # }
}

# ---------- 2. API Gateway REST con autorizador de Cognito ----------
resource "aws_api_gateway_rest_api" "api" {
  name = "${local.prefijo}-api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_authorizer" "cognito" {
  name            = "cognito-lectores"
  rest_api_id     = aws_api_gateway_rest_api.api.id
  type            = "COGNITO_USER_POOLS"
  provider_arns   = [var.user_pool_arn]
  identity_source = "method.request.header.Authorization"
}

# Ruta /clubes
resource "aws_api_gateway_resource" "clubes" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "clubes"
}

# Métodos GET y POST: ambos exigen un token válido de Cognito (sin token -> 401)
resource "aws_api_gateway_method" "clubes" {
  for_each = toset(["GET", "POST"])

  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.clubes.id
  http_method   = each.key
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "clubes" {
  for_each = aws_api_gateway_method.clubes

  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.clubes.id
  http_method             = each.value.http_method
  integration_http_method = "POST" # API Gateway siempre invoca a Lambda con POST
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_alias.live.invoke_arn
}

# Permiso para que API Gateway pueda invocar el alias de la Lambda
resource "aws_lambda_permission" "apigw" {
  statement_id  = "PermitirApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_clubes.function_name
  qualifier     = aws_lambda_alias.live.name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# Despliegue y stage (el stage se llama como el entorno: dev)
resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  # Si cambia algo de la API, se crea un despliegue nuevo
  triggers = {
    redeploy = sha1(jsonencode([
      aws_api_gateway_resource.clubes.id,
      aws_api_gateway_method.clubes,
      aws_api_gateway_integration.clubes,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "api" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.api.id
  stage_name    = var.entorno
}

# Throttling: límite de peticiones. Al superarlo responde 429 (RNF-08 y RNF-21)
resource "aws_api_gateway_method_settings" "todas" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.api.stage_name
  method_path = "*/*"

  settings {
    throttling_rate_limit  = 10
    throttling_burst_limit = 20
    metrics_enabled        = true
  }
}