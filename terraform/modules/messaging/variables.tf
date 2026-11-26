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

variable "correo_alertas" {
  description = "Correo que recibe las alertas de CloudWatch. Debe confirmar la suscripción con el enlace que envía AWS"
  type        = string

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.correo_alertas))
    error_message = "Debe ser un correo válido."
  }
}