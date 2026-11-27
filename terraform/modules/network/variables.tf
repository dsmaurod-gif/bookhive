variable "proyecto" {
  description = "Nombre del proyecto, usado en nombres y etiquetas"
  type        = string
}

variable "entorno" {
  description = "Entorno: dev o prod"
  type        = string
}

variable "region" {
  description = "Región de AWS (se usa para armar el nombre de los VPC endpoints)"
  type        = string
}

variable "vpc_cidr" {
  description = "Rango de direcciones de la VPC"
  type        = string
}

variable "zonas" {
  description = "Zonas de disponibilidad: [AZ A, AZ B]"
  type        = list(string)
}

variable "habilitar_endpoints_monitoreo" {
  description = "Crea los endpoints de CloudWatch (logs y monitoring) para que el agente de las EC2 envíe métricas y logs sin salir a internet. Cada endpoint de interfaz cobra por hora y por zona"
  type        = bool
  default     = true
}