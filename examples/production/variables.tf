variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "name" {
  type    = string
  default = "acme-prod"
}

variable "domain_name" {
  type = string
}

variable "route53_zone_id" {
  type = string
}

variable "container_image" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_secret_arn" {
  description = "Secrets Manager ARN containing the DATABASE_URL value"
  type        = string
}

variable "jwt_secret_arn" {
  description = "Secrets Manager ARN containing the app JWT signing key"
  type        = string
}
