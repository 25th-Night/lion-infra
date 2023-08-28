terraform {

  required_providers {
    ncloud = {
      source = "NaverCloudPlatform/ncloud"
    }
    ssh = {
      source  = "loafoe/ssh"
      version = "2.6.0"
    }
  }
  required_version = ">= 0.13"
}

provider "ncloud" {
  access_key  = var.ncp_access_key
  secret_key  = var.ncp_secret_key
  region      = "KR"
  site        = "public"
  support_vpc = true
}

provider "ssh" {

}

locals {
  env                       = "staging"
  server_image_product_code = "SW.VSVR.OS.LNX64.UBNTU.SVR2004.B050"
  db_port                   = 5432
  db_name                   = "db"
  db_init_script_path       = "db_init_script.tftpl"
  be_port                   = 8000
  be_name                   = "be"
  be_init_script_path       = "be_init_script.tftpl"
}

data "ncloud_server_product" "product" {
  server_image_product_code = local.server_image_product_code

  filter {
    name   = "product_code"
    values = ["SSD"]
    regex  = true
  }

  filter {
    name   = "cpu_count"
    values = ["2"]
  }

  filter {
    name   = "memory_size"
    values = ["4GB"]
  }

  filter {
    name   = "base_block_storage_size"
    values = ["50GB"]
  }

  filter {
    name   = "product_type"
    values = ["HICPU"]
  }
}

resource "ssh_resource" "init_db" {
  depends_on = [module.be]
  when       = "create"

  host     = ncloud_public_ip.db.public_ip
  user     = var.username
  password = var.password

  timeout     = "1m"
  retry_delay = "5s"

  file {
    source      = "${path.module}/set_db_server.sh"
    destination = "/home/${var.username}/init.sh"
    permissions = "0700"
  }

  commands = [
    "/home/${var.username}/init.sh"
  ]
}

resource "ssh_resource" "init_be" {
  depends_on = [module.be]
  when       = "create"

  host     = ncloud_public_ip.be.public_ip
  user     = var.username
  password = var.password

  timeout     = "1m"
  retry_delay = "5s"

  file {
    source      = "${path.module}/set_be_server.sh"
    destination = "/home/${var.username}/init.sh"
    permissions = "0700"
  }

  commands = [
    "/home/${var.username}/init.sh"
  ]
}



module "network" {
  source = "../modules/network"

  ncp_access_key = var.ncp_access_key
  ncp_secret_key = var.ncp_secret_key
  env            = local.env
}


module "db" {
  source             = "../modules/server"
  ncp_access_key     = var.ncp_access_key
  ncp_secret_key     = var.ncp_secret_key
  name               = local.db_name
  env                = local.env
  vpc_id             = module.network.vpc_id
  subnet_id          = module.network.subnet_id
  server_image_code  = local.server_image_product_code
  server_produt_code = data.ncloud_server_product.product.id
  acg_port_range     = local.db_port
  init_script_path   = local.db_init_script_path
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

  ncp_access_key     = var.ncp_access_key
  ncp_secret_key     = var.ncp_secret_key
  name               = local.be_name
  env                = local.env
  vpc_id             = module.network.vpc_id
  subnet_id          = module.network.subnet_id
  server_image_code  = local.server_image_product_code
  server_produt_code = data.ncloud_server_product.product.id
  acg_port_range     = local.be_port
  init_script_path   = local.be_init_script_path
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
    db_host                = ncloud_public_ip.db.public_ip
  }
}

resource "ncloud_public_ip" "db" {
  server_instance_no = module.db.server_instance_no
}

resource "ncloud_public_ip" "be" {
  server_instance_no = module.be.server_instance_no
}

module "load_balancer" {
  source = "../modules/loadBalancer"

  ncp_access_key        = var.ncp_access_key
  ncp_secret_key        = var.ncp_secret_key
  env                   = local.env
  vpc_id                = module.network.vpc_id
  be_server_instance_no = module.be.server_instance_no
}





