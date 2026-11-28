output "cloudfront_dominio" {
  description = "Dominio público de CloudFront (la entrada de BookHive)"
  value       = aws_cloudfront_distribution.borde.domain_name
}

output "waf_nombre" {
  description = "Nombre de la ACL del WAF"
  value       = aws_wafv2_web_acl.borde.name
}