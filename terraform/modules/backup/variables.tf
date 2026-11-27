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

variable "acciones_alarma" {
  description = "ARN de los temas SNS a los que avisa la alarma de respaldo fallido"
  type        = list(string)
  default     = []
}