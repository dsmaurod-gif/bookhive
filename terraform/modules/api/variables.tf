variable "proyecto" {
  description = "Nombre del proyecto"
  type        = string
}

variable "entorno" {
  description = "Entorno: dev o prod (también es el nombre del stage de la API)"
  type        = string
}

variable "subredes_aplicacion" {
  description = "Subredes privadas de aplicación (una por AZ) donde corre la Lambda"
  type        = list(string)
}

variable "sg_lambda_id" {
  description = "Grupo de seguridad de la Lambda (SG-lambda)"
  type        = string
}

variable "user_pool_arn" {
  description = "ARN del user pool de Cognito que valida el autorizador"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN del tema SNS donde la Lambda publica eventos"
  type        = string
}

variable "secreto_arn" {
  description = "ARN del secreto de Secrets Manager que la Lambda lee"
  type        = string
}