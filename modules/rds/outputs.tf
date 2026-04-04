output "db_instance_id" {
  value = aws_db_instance.this.id
}

output "endpoint" {
  value = aws_db_instance.this.endpoint
}

output "port" {
  value = aws_db_instance.this.port
}

output "security_group_id" {
  value = aws_security_group.rds.id
}

output "kms_key_arn" {
  value = local.kms_key_arn
}

output "connection_string_template" {
  description = "Render with your password: postgres://user:PASS@host:port/db"
  value       = "postgres://${var.master_username}:__PASSWORD__@${aws_db_instance.this.endpoint}/${var.db_name}"
  sensitive   = false
}
