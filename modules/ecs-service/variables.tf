variable "name" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "aws_region" { type = string }

variable "create_cluster" {
  type    = bool
  default = true
}
variable "cluster_arn" {
  type    = string
  default = null
}
variable "container_insights" {
  type    = bool
  default = false
}

variable "alb_security_group_id" { type = string }
variable "https_listener_arn" { type = string }
variable "host_patterns" {
  type        = list(string)
  description = "Hostnames the ALB should route to this service (e.g. ['app.example.com'])."
}
variable "path_patterns" {
  type    = list(string)
  default = []
}
variable "listener_priority" {
  type    = number
  default = 100
}

variable "container_name" {
  type    = string
  default = "app"
}
variable "container_image" { type = string }
variable "container_port" {
  type    = number
  default = 8080
}
variable "health_check_path" {
  type    = string
  default = "/health"
}

variable "task_cpu" {
  type    = number
  default = 512
}
variable "task_memory" {
  type    = number
  default = 1024
}

variable "environment" {
  type    = map(string)
  default = {}
}
variable "secrets" {
  description = "map of env var name to ARN (SSM parameter or Secrets Manager secret)"
  type        = map(string)
  default     = {}
}

variable "desired_count" {
  type    = number
  default = 2
}
variable "min_count" {
  type    = number
  default = 2
}
variable "max_count" {
  type    = number
  default = 10
}
variable "target_cpu_pct" {
  type    = number
  default = 55
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "enable_exec" {
  description = "Enable `aws ecs execute-command` for debugging"
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
