# Multi-AZ DBクラスター（学習用・一時的な検証）
resource "aws_rds_cluster" "multiaz_demo" {
  cluster_identifier = "${var.project_name}-${var.environment}-multiaz-demo"
  engine             = "postgres"
  engine_version     = "16.13"

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  master_username = var.db_username
  master_password = random_password.db.result

  storage_type      = "io1"
  allocated_storage = 100
  iops              = 1000

  db_cluster_instance_class = "db.m5d.xlarge"

  skip_final_snapshot = true

  tags = {
    Name = "${var.project_name}-${var.environment}-multiaz-demo"
  }
}