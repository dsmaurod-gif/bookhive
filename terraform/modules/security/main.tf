locals {
  prefijo = "${var.proyecto}-${var.entorno}"
}

resource "aws_security_group" "alb" {
  name        = "${local.prefijo}-sg-alb"
  description = "ALB regional: entrada HTTP del PMV, salida solo hacia EC2 Sync"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.prefijo}-sg-alb"
  }
}

resource "aws_security_group" "app" {
  name        = "${local.prefijo}-sg-app"
  description = "EC2 Sync: acepta solo del ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.prefijo}-sg-app"
  }
}

resource "aws_security_group" "cache" {
  name        = "${local.prefijo}-sg-cache"
  description = "ElastiCache: acepta solo de EC2 Sync"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.prefijo}-sg-cache"
  }
}

resource "aws_security_group" "db" {
  name        = "${local.prefijo}-sg-db"
  description = "Aurora PostgreSQL: acepta solo de las Lambda"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.prefijo}-sg-db"
  }
}

resource "aws_security_group" "lambda" {
  name        = "${local.prefijo}-sg-lambda"
  description = "Lambda de la API: salida hacia Aurora y hacia los VPC endpoints"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.prefijo}-sg-lambda"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each = toset(var.ip_permitida)

  security_group_id = aws_security_group.alb.id
  description       = "HTTP del PMV desde ${each.value}"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "alb_hacia_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Hacia EC2 Sync"
  ip_protocol                  = "tcp"
  from_port                    = var.puerto_app
  to_port                      = var.puerto_app
  referenced_security_group_id = aws_security_group.app.id
}

resource "aws_vpc_security_group_ingress_rule" "app_desde_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "Puerto de la app desde el ALB"
  ip_protocol                  = "tcp"
  from_port                    = var.puerto_app
  to_port                      = var.puerto_app
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "app_https" {
  security_group_id = aws_security_group.app.id
  description       = "HTTPS hacia los VPC endpoints"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "app_hacia_cache" {
  security_group_id            = aws_security_group.app.id
  description                  = "Redis hacia ElastiCache"
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
  referenced_security_group_id = aws_security_group.cache.id
}

resource "aws_vpc_security_group_ingress_rule" "cache_desde_app" {
  security_group_id            = aws_security_group.cache.id
  description                  = "Redis desde EC2 Sync"
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
  referenced_security_group_id = aws_security_group.app.id
}

resource "aws_vpc_security_group_ingress_rule" "db_desde_lambda" {
  security_group_id            = aws_security_group.db.id
  description                  = "PostgreSQL desde las Lambda"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.lambda.id
}

resource "aws_vpc_security_group_egress_rule" "lambda_hacia_db" {
  security_group_id            = aws_security_group.lambda.id
  description                  = "PostgreSQL hacia Aurora"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.db.id
}

resource "aws_vpc_security_group_egress_rule" "lambda_https" {
  security_group_id = aws_security_group.lambda.id
  description       = "HTTPS hacia los VPC endpoints (SNS y Secrets Manager)"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}