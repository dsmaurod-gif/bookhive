locals {
  prefijo = "${var.proyecto}-${var.entorno}"
}

resource "aws_wafv2_web_acl" "borde" {
  # checkov:skip=CKV2_AWS_31:El registro de WAF se añade en la evolucion; el PMV usa las reglas administradas
  provider = aws.virginia

  name  = "${local.prefijo}-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "reglas-comunes"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.prefijo}-waf-comunes"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "limite-por-ip"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.prefijo}-waf-limite-ip"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "entradas-maliciosas"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.prefijo}-waf-entradas-maliciosas"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.prefijo}-waf"
    sampled_requests_enabled   = true
  }
}