variable "name" { type = string }
variable "vpc_id" { type = string }
variable "db_subnet_ids" { type = list(string) }
variable "allowed_client_sg_id" {
  description = "Security group of the app/task that will connect"
  type        = string
}

variable "engine_version" {
  type    = string
  default = "16.3"
}
variable "parameter_group_family" {
  type    = string
  default = "postgres16"
}

variable "instance_class" {
  type    = string
  default = "db.t3.medium"
}
variable "allocated_storage_gb" {
  type    = number
  default = 50
}
variable "max_allocated_storage_gb" {
  type    = number
  default = 200
}

variable "db_name" { type = string }
variable "master_username" {
  type    = string
  default = "app"
}
variable "master_password" {
  type      = string
  sensitive = true
}

variable "multi_az" {
  type    = bool
  default = false
}
variable "backup_retention_days" {
  type    = number
  default = 7
}
variable "deletion_protection" {
  type    = bool
  default = true
}
variable "take_final_snapshot" {
  type    = bool
  default = true
}

variable "performance_insights" {
  type    = bool
  default = false
}
variable "enhanced_monitoring_interval" {
  description = "0 to disable; else 1, 5, 10, 15, 30, or 60 seconds."
  type        = number
  default     = 0
}

variable "create_kms_key" {
  type    = bool
  default = true
}
variable "kms_key_arn" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
