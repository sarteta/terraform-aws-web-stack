locals {
  common_tags = merge({
    "Project"   = var.name
    "ManagedBy" = "terraform"
    "Module"    = "terraform-aws-web-stack/rds"
  }, var.tags)
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-rds"
  subnet_ids = var.db_subnet_ids
  tags       = local.common_tags
}

resource "aws_security_group" "rds" {
  name        = "${var.name}-rds"
  description = "RDS — only ECS service can reach it"
  vpc_id      = var.vpc_id
  tags        = merge(local.common_tags, { "Name" = "${var.name}-rds" })
}

resource "aws_security_group_rule" "rds_ingress_app" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = var.allowed_client_sg_id
  security_group_id        = aws_security_group.rds.id
  description              = "Postgres from app tasks"
}

resource "aws_kms_key" "rds" {
  count                   = var.create_kms_key ? 1 : 0
  description             = "${var.name} RDS encryption"
  deletion_window_in_days = 14
  enable_key_rotation     = true
  tags                    = local.common_tags
}

locals {
  kms_key_arn = var.create_kms_key ? aws_kms_key.rds[0].arn : var.kms_key_arn
}

resource "aws_db_parameter_group" "this" {
  name   = "${var.name}-pg"
  family = var.parameter_group_family

  # Secure-ish defaults the team tends to want
  parameter {
    name  = "log_statement"
    value = "ddl"
  }
  parameter {
    name  = "log_min_duration_statement"
    value = "500"
  }

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "this" {
  identifier = var.name

  engine               = "postgres"
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  allocated_storage    = var.allocated_storage_gb
  max_allocated_storage = var.max_allocated_storage_gb
  storage_type         = "gp3"
  storage_encrypted    = true
  kms_key_id           = local.kms_key_arn

  db_name  = var.db_name
  username = var.master_username
  password = var.master_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.this.name
  publicly_accessible    = false

  multi_az                    = var.multi_az
  backup_retention_period     = var.backup_retention_days
  backup_window               = "03:00-04:00"
  maintenance_window           = "Mon:04:00-Mon:05:00"
  auto_minor_version_upgrade  = true
  deletion_protection         = var.deletion_protection
  delete_automated_backups    = false
  copy_tags_to_snapshot       = true
  skip_final_snapshot         = !var.take_final_snapshot
  final_snapshot_identifier   = var.take_final_snapshot ? "${var.name}-final-${formatdate("YYYYMMDDhhmmss", timestamp())}" : null
  performance_insights_enabled = var.performance_insights
  monitoring_interval         = var.enhanced_monitoring_interval

  tags = local.common_tags

  lifecycle {
    ignore_changes = [final_snapshot_identifier, password]
  }
}
