terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.40, < 6.0"
    }
  }

  # Recommended: move state to S3 + DynamoDB lock for a real prod deploy.
  # backend "s3" {
  #   bucket         = "acme-tf-state"
  #   key            = "prod/web-stack.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "acme-tf-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
}

# ------------------------------------------------------------------
#  Production-shape: per-AZ NAT, Multi-AZ RDS, Performance Insights
# ------------------------------------------------------------------

module "vpc" {
  source = "../../modules/vpc"

  name             = var.name
  cidr_block       = "10.10.0.0/16"
  az_count         = 3
  nat_mode         = "per_az"
  enable_flow_logs = true

  tags = local.common_tags
}

module "alb" {
  source = "../../modules/alb"

  name              = var.name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids

  domain_name            = var.domain_name
  route53_zone_id        = var.route53_zone_id
  create_acm_certificate = true
  create_dns_alias       = true

  tags = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  name                 = var.name
  vpc_id               = module.vpc.vpc_id
  db_subnet_ids        = module.vpc.db_private_subnet_ids
  allowed_client_sg_id = module.app.security_group_id

  db_name         = "appdb"
  master_password = var.db_password

  instance_class               = "db.m5.large"
  allocated_storage_gb         = 200
  max_allocated_storage_gb     = 1000
  multi_az                     = true
  backup_retention_days        = 14
  deletion_protection          = true
  take_final_snapshot          = true
  performance_insights         = true
  enhanced_monitoring_interval = 60

  tags = local.common_tags
}

module "app" {
  source = "../../modules/ecs-service"

  name               = "${var.name}-app"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  aws_region         = var.aws_region

  alb_security_group_id = module.alb.security_group_id
  https_listener_arn    = module.alb.https_listener_arn
  host_patterns         = [var.domain_name]

  container_image = var.container_image
  container_port  = 8080
  task_cpu        = 1024
  task_memory     = 2048

  desired_count  = 4
  min_count      = 4
  max_count      = 20
  target_cpu_pct = 55

  container_insights = true
  log_retention_days = 90

  environment = {
    NODE_ENV = "production"
  }
  secrets = {
    DATABASE_URL = var.db_secret_arn
    JWT_SECRET   = var.jwt_secret_arn
  }

  tags = local.common_tags
}

locals {
  common_tags = {
    "Env"     = "prod"
    "Project" = var.name
    "Owner"   = "platform-team"
  }
}
