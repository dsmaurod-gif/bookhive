output "vpc_id" {
  description = "Identificador de la VPC"
  value       = aws_vpc.principal.id
}

output "vpc_cidr" {
  description = "Rango de direcciones de la VPC"
  value       = aws_vpc.principal.cidr_block
}

output "subredes_publicas_ids" {
  description = "Subredes públicas, una por AZ (nodo del ALB)"
  value       = aws_subnet.publica[*].id
}

output "subredes_aplicacion_ids" {
  description = "Subredes privadas de aplicación, una por AZ (EC2 Sync y Lambda)"
  value       = aws_subnet.aplicacion[*].id
}

output "subredes_datos_ids" {
  description = "Subredes privadas de datos, una por AZ (ElastiCache y Aurora)"
  value       = aws_subnet.datos[*].id
}