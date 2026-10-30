variable "proyecto" {
  description = "Nombre del proyecto"
  type        = string
}

variable "entorno" {
  description = "Entorno: dev o prod"
  type        = string
}

variable "zonas" {
  description = "Zonas de disponibilidad: [AZ A, AZ B]"
  type        = list(string)
}

variable "subredes_datos" {
  description = "Subredes privadas de datos (una por AZ)"
  type        = list(string)
}

variable "sg_cache_id" {
  description = "Grupo de seguridad de ElastiCache"
  type        = string
}

variable "sg_db_id" {
  description = "Grupo de seguridad de Aurora"
  type        = string
}

variable "habilitar_aurora" {
  description = "Crea Aurora (writer y reader). Cobra por hora"
  type        = bool
  default     = false
}

variable "habilitar_cache" {
  description = "Crea ElastiCache (primario y réplica). Cobra por hora"
  type        = bool
  default     = false
}