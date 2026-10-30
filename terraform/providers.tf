terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

variable "region" { default = "us-east-2" }
variable "proyecto" { default = "bookhive" }
variable "entorno" { default = "dev" }


provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Proyecto  = var.proyecto
      Entorno   = var.entorno
      ManagedBy = "terraform"
    }
  }
}