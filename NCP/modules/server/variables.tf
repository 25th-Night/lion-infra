variable "ncp_access_key" {
  type      = string
  sensitive = true
}

variable "ncp_secret_key" {
  type      = string
  sensitive = true
}

variable "name" {
  type = string
}

variable "env" {
  type = string
}

variable "vpc_id" {
  type = number
}

variable "subnet_id" {
  type = number
}

variable "server_image_code" {
  type = string
}

variable "server_produt_code" {
  type = string
}

variable "acg_port_range" {
  type = number
}

variable "init_script_path" {
  type = string
}

variable "init_script_envs" {
  type = map(any)
}
