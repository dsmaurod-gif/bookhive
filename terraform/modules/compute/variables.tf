
variable "proyecto" {
  description = "Nombre del proyecto"
  type        = string
}

variable "entorno" {
  description = "Entorno de despliegue"
  type        = string
}

variable "vpc_id" {
  description = "Identificador de la VPC"
  type        = string
}

variable "subredes_publicas_ids" {
  description = "Identificadores de las subredes públicas"
  type        = list(string)
}

variable "subredes_aplicacion_ids" {
  description = "Identificadores de las subredes privadas de aplicación"
  type        = list(string)
}

variable "sg_alb_id" {
  description = "Grupo de seguridad del balanceador"
  type        = string
}

variable "sg_app_id" {
  description = "Grupo de seguridad de las instancias EC2"
  type        = string
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.micro"
}

variable "asg_min" {
  description = "Mínimo de instancias del Auto Scaling"
  type        = number
  default     = 2
}

variable "asg_max" {
  description = "Máximo de instancias del Auto Scaling"
  type        = number
  default     = 10
}

variable "asg_deseado" {
  description = "Cantidad inicial de instancias"
  type        = number
  default     = 2
}

variable "puerto_app" {
  description = "Puerto de comunicación de la aplicación"
  type        = number
  default     = 8080
}
