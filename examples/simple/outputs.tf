output "alb_dns" {
  value       = module.alb.alb_dns_name
  description = "Public DNS of the ALB"
}

output "app_url" {
  value = "https://${var.domain_name}"
}

output "rds_endpoint" {
  value = module.rds.endpoint
}
