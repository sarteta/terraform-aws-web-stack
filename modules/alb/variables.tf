variable "name" {
  type        = string
  description = "Short name prefix"
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Must be at least 2 public subnets in different AZs."
}

variable "domain_name" {
  type        = string
  description = "Apex domain or hostname the ALB will serve (e.g. app.example.com)."
}

variable "route53_zone_id" {
  type        = string
  description = "Hosted zone ID for DNS validation + alias records."
  default     = null
}

variable "create_acm_certificate" {
  type        = bool
  default     = true
  description = "If false, pass in certificate_arn instead."
}

variable "certificate_arn" {
  type    = string
  default = null
}

variable "create_dns_alias" {
  type    = bool
  default = true
}

variable "enable_http_redirect" {
  type        = bool
  default     = true
  description = "Listen on :80 and 301 to :443."
}

variable "tags" {
  type    = map(string)
  default = {}
}
