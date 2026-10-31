variable "proyecto" {
  description = "Nombre del proyecto"
  type        = string
}

variable "entorno" {
  description = "Entorno: dev o prod"
  type        = string
}

variable "correo_demo" {
  description = "Correo de SES: remitente y destinatario de prueba. En sandbox debe verificarse"
  type        = string
}
