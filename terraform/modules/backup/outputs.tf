output "vault_nombre" {
  description = "Nombre de la bóveda de AWS Backup"
  value       = aws_backup_vault.principal.name
}

output "plan_id" {
  description = "ID del plan de respaldo"
  value       = aws_backup_plan.diario.id
}