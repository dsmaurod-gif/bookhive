variable "proyecto" {
  description = "Nombre del proyecto"
  type        = string
}

variable "entorno" {
  description = "Entorno: dev o prod"
  type        = string
}

variable "region" {
  description = "Región de AWS (la usan los gráficos del panel)"
  type        = string
}

variable "sns_alertas_arn" {
  description = "ARN del tema SNS al que avisan las alarmas"
  type        = string
}

variable "alb_arn_suffix" {
  description = "Sufijo del ARN del ALB (dimensión LoadBalancer)"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Sufijo del ARN del grupo de destino (dimensión TargetGroup)"
  type        = string
}

variable "asg_nombre" {
  description = "Nombre del grupo de Auto Scaling de EC2 Sync"
  type        = string
}

variable "api_nombre" {
  description = "Nombre de la API REST (dimensión ApiName)"
  type        = string
}

variable "api_stage" {
  description = "Nombre del stage de la API (dimensión Stage)"
  type        = string
}

variable "lambda_api_nombre" {
  description = "Nombre de la Lambda de la API de clubes"
  type        = string
}

variable "lambda_notificador_nombre" {
  description = "Nombre de la Lambda notificador"
  type        = string
}

variable "tabla_notas_nombre" {
  description = "Nombre de la tabla DynamoDB de notas"
  type        = string
}

variable "dlq_nombre" {
  description = "Nombre de la cola de mensajes fallidos"
  type        = string
}