variable "name" {
  description = "Short name prefix for all resources (e.g. 'acme-prod')"
  type        = string
}

variable "cidr_block" {
  description = "VPC IPv4 CIDR (e.g. 10.20.0.0/16)"
  type        = string
  default     = "10.20.0.0/16"
}

variable "az_count" {
  description = "How many AZs to span. 2 is fine for most workloads; 3 for higher SLAs."
  type        = number
  default     = 2
  validation {
    condition     = var.az_count >= 2 && var.az_count <= 4
    error_message = "az_count must be between 2 and 4."
  }
}

variable "nat_mode" {
  description = "'single' (1 NAT, cheaper, non-HA) or 'per_az' (N NAT, HA, ~$32/mo each)."
  type        = string
  default     = "single"
  validation {
    condition     = contains(["single", "per_az"], var.nat_mode)
    error_message = "nat_mode must be 'single' or 'per_az'."
  }
}

variable "enable_flow_logs" {
  description = "Send VPC flow logs to CloudWatch (costs extra)."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags merged into every resource"
  type        = map(string)
  default     = {}
}
