output "db_public_ip" {
  value = module.db.public_ip
}

output "be_public_ip" {
  value = module.be.public_ip
}

output "load_balancer_domain" {
  value = module.load_balancer.load_balancer_domain
}
