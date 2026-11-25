# 1. DBサブネットグループ：RDSをどのプライベートサブネットに配置するか
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = [for s in aws_subnet.private_rds : s.id]

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  }
}

# 2. RDSインスタンス本体
resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-${var.environment}-db"
  engine         = "postgres"
  engine_version = "16"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "appdb"
  username = var.db_username
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az            = true
  publicly_accessible = false
  skip_final_snapshot = true # 学習用途：destroy時に最終スナップショットを作らない
  apply_immediately   = true # ← 追加：変更をメンテナンスウィンドウ待ちにせず即時反映

  tags = {
    Name = "${var.project_name}-${var.environment}-db"
  }
}