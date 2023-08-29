output "load_balancer_domain" {
  value = aws_lb.main.dns_name
}
