variable "proyecto" {
  description = "Nombre del proyecto"
  type        = string
}

variable "entorno" {
  description = "Entorno: dev o prod"
  type        = string
}

variable "vpc_id" {
  description = "VPC donde se crean los grupos de seguridad"
  type        = string
}

variable "ip_permitida" {
  description = "CIDR que pueden llamar al ALB por HTTP (PMV). En la arquitectura final solo entra CloudFront por 443"
  type        = list(string)
}

variable "puerto_app" {
  description = "Puerto en el que escucha EC2 Sync"
  type        = number
  default     = 3000
}
