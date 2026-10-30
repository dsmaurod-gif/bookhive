terraform {
  backend "s3" {
    key          = "lab09/dev/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
}