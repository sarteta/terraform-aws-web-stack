variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "name" {
  type    = string
  default = "web-stack-simple"
}

variable "domain_name" {
  type        = string
  description = "Hostname for the ALB (e.g. app.example.com)"
}

variable "route53_zone_id" {
  type        = string
  description = "Route53 hosted zone for domain_name's parent"
}

variable "container_image" {
  type        = string
  description = "ECR or Docker Hub image for the app"
  default     = "public.ecr.aws/nginx/nginx:1.25"
}

variable "db_password" {
  type      = string
  sensitive = true
}
