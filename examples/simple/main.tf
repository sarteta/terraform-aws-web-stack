terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.40, < 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ------------------------------------------------------------------
#  Simple single-AZ NAT dev stack
#  - 1 NAT
#  - 2 AZs
#  - db.t3.medium, non-Multi-AZ
#  - 2 Fargate tasks, autoscales 2→6
# ------------------------------------------------------------------

module "vpc" {
  source = "../../modules/vpc"

  name       = var.name
  cidr_block = "10.30.0.0/16"
  az_count   = 2
  nat_mode   = "single"

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

  instance_class       = "db.t3.medium"
  allocated_storage_gb = 50
  multi_az             = false
  deletion_protection  = false
  take_final_snapshot  = false

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
  task_cpu        = 512
  task_memory     = 1024

  desired_count = 2
  min_count     = 2
  max_count     = 6

  environment = {
    NODE_ENV = "production"
  }

  tags = local.common_tags
}

locals {
  common_tags = {
    "Env"     = "dev"
    "Project" = var.name
  }
}
