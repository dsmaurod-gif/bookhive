variable "proyecto" {
  description = "Nombre del proyecto"
  type        = string
}

variable "entorno" {
  description = "Entorno: dev o prod"
  type        = string
}

variable "recursos_arn" {
  description = "ARN de los recursos que respalda AWS Backup (DynamoDB y, si existe, Aurora)"
  type        = list(string)
}