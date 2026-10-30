variable "proyecto" {
  description = "Nombre del proyecto"
  type        = string
}

variable "entorno" {
  description = "Entorno: dev o prod"
  type        = string
}

variable "region" {
  description = "Región de AWS (se pasa a los comandos aws de la instancia)"
  type        = string
}

variable "vpc_id" {
  description = "VPC donde se crea el grupo de destino del ALB"
  type        = string
}

variable "subredes_publicas" {
  description = "Subredes públicas (una por AZ) donde vive el ALB"
  type        = list(string)
}

variable "subredes_aplicacion" {
  description = "Subredes privadas de aplicación (una por AZ) donde corren las EC2 Sync"
  type        = list(string)
}

variable "sg_alb_id" {
  description = "Grupo de seguridad del ALB"
  type        = string
}

variable "sg_app_id" {
  description = "Grupo de seguridad de EC2 Sync"
  type        = string
}

variable "tabla_notas_nombre" {
  description = "Nombre de la tabla DynamoDB de notas"
  type        = string
}

variable "tabla_notas_arn" {
  description = "ARN de la tabla DynamoDB de notas"
  type        = string
}

variable "instance_type" {
  description = "Tipo de instancia de EC2 Sync"
  type        = string
  default     = "t3.micro"
}

variable "asg_min" {
  description = "Mínimo de instancias (1 por AZ)"
  type        = number
  default     = 2
}

variable "asg_max" {
  description = "Máximo de instancias (5 por AZ)"
  type        = number
  default     = 10
}

variable "asg_deseado" {
  description = "Cantidad inicial de instancias"
  type        = number
  default     = 2
}

variable "puerto_app" {
  description = "Puerto en el que escucha EC2 Sync (SG-app lo abre solo al ALB)"
  type        = number
  default     = 3000
}