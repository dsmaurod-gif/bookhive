variable "proyecto" {
  description = "Nombre del proyecto, usado en nombres y etiquetas de los recursos"
  type        = string
  default     = "bookhive"
}

variable "entorno" {
  description = "Nombre del entorno: dev o prod"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.entorno)
    error_message = "El entorno debe ser dev o prod."
  }
}

variable "region" {
  description = "Región de AWS donde se despliega la infraestructura (el equipo trabaja en us-east-2; el diagrama dice us-east-1)"
  type        = string
  default     = "us-east-2"
}

variable "vpc_cidr" {
  description = "Rango de direcciones IP de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "zonas" {
  description = "Zonas de disponibilidad: la primera es AZ A y la segunda AZ B"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}

variable "ip_permitida_alb" {
  description = "Rangos CIDR que pueden llamar al ALB por HTTP (solo PMV: en la arquitectura final entra CloudFront)"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for cidr in var.ip_permitida_alb : can(cidrhost(cidr, 0))])
    error_message = "Cada valor debe ser un CIDR válido, por ejemplo 200.10.20.30/32."
  }
}

variable "instance_type" {
  description = "Tipo de instancia de las EC2 Sync"
  type        = string
  default     = "t3.micro"
}

variable "asg_min" {
  description = "Mínimo de instancias del Auto Scaling (1 por AZ)"
  type        = number
  default     = 2
}

variable "asg_max" {
  description = "Máximo de instancias del Auto Scaling (5 por AZ)"
  type        = number
  default     = 10
}

variable "asg_deseado" {
  description = "Cantidad inicial de instancias"
  type        = number
  default     = 2
}

variable "habilitar_aurora" {
  description = "Crea el clúster Aurora (writer y reader). Cobra por hora: dejar en false salvo para la demostración completa"
  type        = bool
  default     = false
}

variable "habilitar_cache" {
  description = "Crea ElastiCache (primario y réplica). Cobra por hora: dejar en false salvo para la demostración completa"
  type        = bool
  default     = false
}

variable "correo_demo" {
  description = "Correo para SES (remitente y destinatario de prueba). En sandbox debe verificarse con el enlace que envía AWS"
  type        = string
  default     = "demo@example.com"

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.correo_demo))
    error_message = "Debe ser un correo válido."
  }
}