terraform {
  backend "s3" {
    key          = "lab09/dev/terraform.tfstate" # La clave del estado es fija y la política IAM del rol de despliegue la limita a esta ruta.
    use_lockfile = true
    encrypt      = true
  }
}