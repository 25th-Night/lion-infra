terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

locals {
  env                 = "staging"
  ami                 = "ami-0c9c942bd7bf113a2"
  instance_type       = "t2.micro"
  db_port             = 5432
  db_name             = "db"
  db_init_script_path = "db_init_script.tftpl"
  be_port             = 8000
  be_name             = "be"
  be_init_script_path = "be_init_script.tftpl"

}

module "network" {
  source = "../modules/network"

  env = local.env
}

module "db" {
  source = "../modules/server"

  name             = local.db_name
  env              = local.env
  vpc_id           = module.network.vpc_id
  subnet_id        = module.network.subnet_id
  sc_port_range    = local.db_port
  ami              = local.ami
  instance_type    = local.instance_type
  init_script_path = local.db_init_script_path
  init_script_envs = {
    username          = var.username
    password          = var.password
    postgres_db       = var.postgres_db
    postgres_user     = var.postgres_user
    postgres_password = var.postgres_password
    postgres_port     = var.postgres_port
    postgres_volume   = var.postgres_volume
    db_container_name = var.db_container_name
  }
}

module "be" {
  source = "../modules/server"

  name             = local.be_name
  env              = local.env
  vpc_id           = module.network.vpc_id
  subnet_id        = module.network.subnet_id
  sc_port_range    = local.be_port
  ami              = local.ami
  instance_type    = local.instance_type
  init_script_path = local.be_init_script_path
  init_script_envs = {
    username               = var.username
    password               = var.password
    django_settings_module = var.django_settings_module
    django_secret_key      = var.django_secret_key
    django_container_name  = var.django_container_name
    ncr_host               = var.ncr_host
    ncr_image              = var.ncr_image
    ncp_access_key         = var.ncp_access_key
    ncp_secret_key         = var.ncp_secret_key
    ncp_lb_domain          = var.ncp_lb_domain
    postgres_db            = var.postgres_db
    postgres_user          = var.postgres_user
    postgres_password      = var.postgres_password
    postgres_port          = var.postgres_port
    db_host                = module.db.public_ip
  }
}

module "load_balancer" {
  source = "../modules/loadBalancer"

  env         = local.env
  name        = local.be_name
  vpc_id      = module.network.vpc_id
  subnet_id   = module.network.subnet_id
  instance_id = module.be.instance_id
}
