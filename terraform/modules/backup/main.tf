locals {
  prefijo = "${var.proyecto}-${var.entorno}"
}

# 1. Bóveda: donde se guardan los respaldos
resource "aws_backup_vault" "principal" {
  name          = "${local.prefijo}-vault"
  force_destroy = true # permite destruir la bóveda aunque ya tenga respaldos (laboratorio)
}

# 2. Plan: full diario a las 09:00 UTC, retención de 30 días (RNF-17)
resource "aws_backup_plan" "diario" {
  name = "${local.prefijo}-full-diario"

  rule {
    rule_name         = "full-diario-0900-utc"
    target_vault_name = aws_backup_vault.principal.name
    schedule          = "cron(0 9 * * ? *)" # minuto hora día mes día-semana año (UTC)

    lifecycle {
      delete_after = 30
    }
  }
}

# 3. Rol que AWS Backup asume para leer y respaldar los recursos
data "aws_iam_policy_document" "backup_confianza" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backup" {
  name               = "${local.prefijo}-backup-role"
  assume_role_policy = data.aws_iam_policy_document.backup_confianza.json
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# 4. Selección: qué recursos entran en el plan
resource "aws_backup_selection" "recursos" {
  name         = "${local.prefijo}-recursos"
  plan_id      = aws_backup_plan.diario.id
  iam_role_arn = aws_iam_role.backup.arn
  resources    = var.recursos_arn
}

# 5. Alarma: avisa si falla un respaldo (CloudWatch).
#    Verificar en la consola (CloudWatch > Métricas > AWS/Backup) las dimensiones disponibles.
resource "aws_cloudwatch_metric_alarm" "respaldo_fallido" {
  alarm_name          = "${local.prefijo}-respaldo-fallido"
  alarm_description   = "Un respaldo de AWS Backup falló"
  namespace           = "AWS/Backup"
  metric_name         = "NumberOfBackupJobsFailed"
  statistic           = "Sum"
  period              = 3600
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
}