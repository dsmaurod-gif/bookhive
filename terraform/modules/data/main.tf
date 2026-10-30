locals {
  prefijo = "${var.proyecto}-${var.entorno}"
}

data "aws_caller_identity" "actual" {}

resource "aws_dynamodb_table" "notas" {
  name         = "${local.prefijo}-notas"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }
}

resource "aws_s3_bucket" "app" {
  bucket        = "${local.prefijo}-app-${data.aws_caller_identity.actual.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "app" {
  bucket                  = aws_s3_bucket.app.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app" {
  bucket = aws_s3_bucket.app.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.app.id
  key          = "index.html"
  content      = "<h1>BookHive (PMV)</h1><p>Aplicación web de ejemplo.</p>"
  content_type = "text/html"
}

resource "random_password" "db" {
  length  = 24
  special = false
}

resource "aws_secretsmanager_secret" "db" {
  name                    = "${local.prefijo}/aurora"
  description             = "Credenciales de Aurora PostgreSQL de BookHive"
  recovery_window_in_days = 0 # borrado inmediato: así se puede volver a crear tras un destroy
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = jsonencode({
    username = "bookhive_admin"
    password = random_password.db.result
    engine   = "postgres"
    dbname   = "bookhive"
    port     = 5432
    host     = var.habilitar_aurora ? aws_rds_cluster.aurora[0].endpoint : ""
  })
}

resource "aws_db_subnet_group" "aurora" {
  count = var.habilitar_aurora ? 1 : 0

  name       = "${local.prefijo}-aurora"
  subnet_ids = var.subredes_datos
}

resource "aws_rds_cluster" "aurora" {
  count = var.habilitar_aurora ? 1 : 0

  cluster_identifier      = "${local.prefijo}-aurora"
  engine                  = "aurora-postgresql"
  database_name           = "bookhive"
  master_username         = "bookhive_admin"
  master_password         = random_password.db.result
  db_subnet_group_name    = aws_db_subnet_group.aurora[0].name
  vpc_security_group_ids  = [var.sg_db_id]
  storage_encrypted       = true
  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true

  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 1
  }
}

resource "aws_rds_cluster_instance" "writer" {
  count = var.habilitar_aurora ? 1 : 0

  identifier           = "${local.prefijo}-aurora-writer"
  cluster_identifier   = aws_rds_cluster.aurora[0].id
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.aurora[0].engine
  engine_version       = aws_rds_cluster.aurora[0].engine_version
  availability_zone    = var.zonas[0]
  promotion_tier       = 0
  db_subnet_group_name = aws_db_subnet_group.aurora[0].name
}

resource "aws_rds_cluster_instance" "reader" {
  count = var.habilitar_aurora ? 1 : 0

  identifier           = "${local.prefijo}-aurora-reader"
  cluster_identifier   = aws_rds_cluster.aurora[0].id
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.aurora[0].engine
  engine_version       = aws_rds_cluster.aurora[0].engine_version
  availability_zone    = var.zonas[1]
  promotion_tier       = 1
  db_subnet_group_name = aws_db_subnet_group.aurora[0].name

  depends_on = [aws_rds_cluster_instance.writer]
}

resource "aws_elasticache_subnet_group" "cache" {
  count = var.habilitar_cache ? 1 : 0

  name       = "${local.prefijo}-cache"
  subnet_ids = var.subredes_datos
}

resource "aws_elasticache_replication_group" "cache" {
  count = var.habilitar_cache ? 1 : 0

  replication_group_id        = "${local.prefijo}-cache"
  description                 = "Estado efimero de las salas de BookHive (TTL)"
  engine                      = "redis"
  engine_version              = "7.1"
  node_type                   = "cache.t3.micro"
  port                        = 6379
  num_cache_clusters          = 2
  preferred_cache_cluster_azs = var.zonas
  automatic_failover_enabled  = true
  multi_az_enabled            = true
  subnet_group_name           = aws_elasticache_subnet_group.cache[0].name
  security_group_ids          = [var.sg_cache_id]
  at_rest_encryption_enabled  = true
  transit_encryption_enabled  = true
  apply_immediately           = true
}