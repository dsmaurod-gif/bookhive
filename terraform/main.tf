module "network" {
  source = "./modules/network"

  proyecto = var.proyecto
  entorno  = var.entorno
  region   = var.region
  vpc_cidr = var.vpc_cidr
  zonas    = var.zonas
}

module "security" {
  source = "./modules/security"

  proyecto     = var.proyecto
  entorno      = var.entorno
  vpc_id       = module.network.vpc_id
  ip_permitida = var.ip_permitida_alb
}

module "data" {
  source = "./modules/data"

  proyecto         = var.proyecto
  entorno          = var.entorno
  zonas            = var.zonas
  subredes_datos   = module.network.subredes_datos_ids
  sg_cache_id      = module.security.sg_cache_id
  sg_db_id         = module.security.sg_db_id
  habilitar_aurora = var.habilitar_aurora
  habilitar_cache  = var.habilitar_cache
}

module "auth" {
  source = "./modules/auth"

  proyecto = var.proyecto
  entorno  = var.entorno
}

module "compute" {
  source = "./modules/compute"

  proyecto            = var.proyecto
  entorno             = var.entorno
  region              = var.region
  subredes_publicas   = module.network.subredes_publicas_ids
  subredes_aplicacion = module.network.subredes_aplicacion_ids
  vpc_id              = module.network.vpc_id
  sg_alb_id           = module.security.sg_alb_id
  sg_app_id           = module.security.sg_app_id
  tabla_notas_nombre  = module.data.tabla_notas_nombre
  tabla_notas_arn     = module.data.tabla_notas_arn
  instance_type       = var.instance_type
  asg_min             = var.asg_min
  asg_max             = var.asg_max
  asg_deseado         = var.asg_deseado
}
