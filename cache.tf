# 1. キャッシュ用セキュリティグループ：ECSからのみ許可
resource "aws_security_group" "redis" {
  name        = "${var.project_name}-${var.environment}-redis-sg"
  description = "Allow cache traffic from ECS only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "From ECS"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-redis-sg"
  }
}

# 2. サブネットグループ（ECS用プライベートサブネットを共用）
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-cache-subnet-group"
  subnet_ids = [for s in aws_subnet.private_ecs : s.id]
}

# 3. Valkeyキャッシュ本体
resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.project_name}-${var.environment}-cache"
  description          = "Valkey cache for ${var.project_name}-${var.environment}"

  engine         = "valkey"
  engine_version = "8.2"
  node_type      = "cache.t3.micro"
  port           = 6379

  num_cache_clusters         = 2    # プライマリ1台＋レプリカ1台
  automatic_failover_enabled = true # 自動フェイルオーバーを有効化
  multi_az_enabled           = true # 複数AZに分散配置
  apply_immediately          = true

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.redis.id]

  tags = {
    Name = "${var.project_name}-${var.environment}-cache"
  }
}