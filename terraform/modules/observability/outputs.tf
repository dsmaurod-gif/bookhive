output "panel_nombre" {
  description = "Nombre del panel de CloudWatch"
  value       = aws_cloudwatch_dashboard.principal.dashboard_name
}