variable "proyecto" {
  description = "Nombre corto del proyecto"
  type        = string
}

variable "entorno" {
  description = "Entorno de despliegue"
  type        = string
}

variable "region" {
  description = "Región donde están el bucket, la API y el ALB"
  type        = string
}

variable "bucket_app" {
  description = "Nombre del bucket S3 con la app web"
  type        = string
}

variable "api_url" {
  description = "URL base de la API (invoke_url de la etapa de API Gateway)"
  type        = string
}

variable "alb_dns_name" {
  description = "Nombre DNS del ALB que atiende /ws"
  type        = string
}