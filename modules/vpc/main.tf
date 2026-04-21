locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # /20 chunks → plenty of room (~4k IPs) per subnet
  public_subnets     = [for i, _ in local.azs : cidrsubnet(var.cidr_block, 4, i)]
  private_subnets    = [for i, _ in local.azs : cidrsubnet(var.cidr_block, 4, i + 4)]
  db_private_subnets = [for i, _ in local.azs : cidrsubnet(var.cidr_block, 4, i + 8)]

  nat_count = var.nat_mode == "per_az" ? length(local.azs) : 1

  common_tags = merge({
    "Project"   = var.name
    "ManagedBy" = "terraform"
    "Module"    = "terraform-aws-web-stack/vpc"
  }, var.tags)
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(local.common_tags, { "Name" = "${var.name}-vpc" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { "Name" = "${var.name}-igw" })
}

# ---- public subnets (one per AZ) ----
resource "aws_subnet" "public" {
  count                   = length(local.azs)
  vpc_id                  = aws_vpc.this.id
  availability_zone       = local.azs[count.index]
  cidr_block              = local.public_subnets[count.index]
  map_public_ip_on_launch = true
  tags = merge(local.common_tags, {
    "Name" = "${var.name}-public-${local.azs[count.index]}"
    "Tier" = "public"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { "Name" = "${var.name}-public-rt" })
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ---- NAT (single or per-AZ) ----
resource "aws_eip" "nat" {
  count  = local.nat_count
  domain = "vpc"
  tags   = merge(local.common_tags, { "Name" = "${var.name}-nat-${count.index}" })
}

resource "aws_nat_gateway" "this" {
  count         = local.nat_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags          = merge(local.common_tags, { "Name" = "${var.name}-nat-${count.index}" })

  depends_on = [aws_internet_gateway.this]
}

# ---- private app subnets ----
resource "aws_subnet" "private" {
  count             = length(local.azs)
  vpc_id            = aws_vpc.this.id
  availability_zone = local.azs[count.index]
  cidr_block        = local.private_subnets[count.index]
  tags = merge(local.common_tags, {
    "Name" = "${var.name}-private-${local.azs[count.index]}"
    "Tier" = "private"
  })
}

resource "aws_route_table" "private" {
  count  = length(local.azs)
  vpc_id = aws_vpc.this.id
  tags = merge(local.common_tags, {
    "Name" = "${var.name}-private-rt-${local.azs[count.index]}"
  })
}

resource "aws_route" "private_default" {
  count                  = length(local.azs)
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  # If nat_mode=single, every private RT points at the single NAT.
  # If nat_mode=per_az, each RT points at its own AZ's NAT.
  nat_gateway_id = var.nat_mode == "per_az" ? aws_nat_gateway.this[count.index].id : aws_nat_gateway.this[0].id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# ---- db-private subnets (no default route — RDS only needs VPC-local) ----
resource "aws_subnet" "db_private" {
  count             = length(local.azs)
  vpc_id            = aws_vpc.this.id
  availability_zone = local.azs[count.index]
  cidr_block        = local.db_private_subnets[count.index]
  tags = merge(local.common_tags, {
    "Name" = "${var.name}-db-${local.azs[count.index]}"
    "Tier" = "db-private"
  })
}

resource "aws_route_table" "db_private" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { "Name" = "${var.name}-db-private-rt" })
}

resource "aws_route_table_association" "db_private" {
  count          = length(aws_subnet.db_private)
  subnet_id      = aws_subnet.db_private[count.index].id
  route_table_id = aws_route_table.db_private.id
}

# ---- Flow logs (optional) ----
resource "aws_cloudwatch_log_group" "flow" {
  count             = var.enable_flow_logs ? 1 : 0
  name              = "/aws/vpc/${var.name}/flow-logs"
  retention_in_days = 30
  tags              = local.common_tags
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${var.name}-vpc-flow-logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  role  = aws_iam_role.flow_logs[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
      ]
      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "this" {
  count                = var.enable_flow_logs ? 1 : 0
  iam_role_arn         = aws_iam_role.flow_logs[0].arn
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.flow[0].arn
  traffic_type         = "REJECT" # save money; only care about rejects for debugging
  vpc_id               = aws_vpc.this.id
}
