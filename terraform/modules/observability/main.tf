locals {
  prefijo = "${var.proyecto}-${var.entorno}"

  # Dimensiones con las que CloudWatch identifica el ALB y su grupo de destino
  dimensiones_alb = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }
}