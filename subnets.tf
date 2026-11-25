locals {
  azs = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]

  # 1段階目：層ごとに専用の/18ブロックを確保（10.0.0.0/16を4分割）
  public_cidr      = cidrsubnet(var.vpc_cidr, 2, 0) # 10.0.0.0/18
  private_ecs_cidr = cidrsubnet(var.vpc_cidr, 2, 1) # 10.0.64.0/18
  private_rds_cidr = cidrsubnet(var.vpc_cidr, 2, 2) # 10.0.128.0/18
  # 10.0.192.0/18 は将来の4層目用に予約（未使用）
}

# 1. パブリックサブネット（ALB / NAT Gateway用）
resource "aws_subnet" "public" {
  for_each = { for idx, az in local.azs : az => idx }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(local.public_cidr, 6, each.value) # 10.0.0.0/24, 10.0.1.0/24...
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-public-${each.key}"
    Tier = "public"
  }
}

# 2. プライベートサブネット：ECS用
resource "aws_subnet" "private_ecs" {
  for_each = { for idx, az in local.azs : az => idx }

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(local.private_ecs_cidr, 6, each.value) # 10.0.64.0/24, 10.0.65.0/24...
  availability_zone = each.key

  tags = {
    Name = "${var.project_name}-${var.environment}-private-ecs-${each.key}"
    Tier = "private-ecs"
  }
}

# 3. プライベートサブネット：RDS用
resource "aws_subnet" "private_rds" {
  for_each = { for idx, az in local.azs : az => idx }

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(local.private_rds_cidr, 6, each.value) # 10.0.128.0/24, 10.0.129.0/24...
  availability_zone = each.key

  tags = {
    Name = "${var.project_name}-${var.environment}-private-rds-${each.key}"
    Tier = "private-rds"
  }
}

# 4. NATゲートウェイ（コスト削減のため1AZ構成の例。高可用性ならfor_eachで各AZに配置）
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public["ap-northeast-1a"].id

  tags = {
    Name = "${var.project_name}-${var.environment}-nat"
  }

  depends_on = [aws_internet_gateway.igw]
}

# 5. ルートテーブル
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# 6.ECS用ルートテーブル（NATゲートウェイ経由で外部通信）
resource "aws_route_table" "private_ecs" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-private-ecs-rt"
  }
}

resource "aws_route_table_association" "private_ecs" {
  for_each = aws_subnet.private_ecs

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_ecs.id
}

# 7.RDS用ルートテーブル（デフォルトルートなしでインターネット遮断）
resource "aws_route_table" "private_rds" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-private-rds-rt"
  }
}

resource "aws_route_table_association" "private_rds" {
  for_each = aws_subnet.private_rds

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_rds.id
}