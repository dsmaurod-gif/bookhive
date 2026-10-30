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