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