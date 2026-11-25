# 1. 安全なランダムパスワードを生成
resource "random_password" "db" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# 2. Secrets Managerに「箱」を作る
resource "aws_secretsmanager_secret" "db" {
  name        = "${var.project_name}/${var.environment}/db-credentials"
  description = "RDSのマスターユーザー認証情報"

  tags = {
    Name = "${var.project_name}-${var.environment}-db-secret"
  }
}

# 3. 箱の中身（実際の認証情報）を書き込む
resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
    engine   = "postgres"
    host     = aws_db_instance.main.address
    port     = 5432
    dbname   = "appdb"
  })
}