# AWSリージョンの定義
variable "aws_region" {
  type        = string
  description = "リソースをデプロイするAWSリージョン"
  default     = "ap-northeast-1" # 東京リージョン
}

# 環境名の定義
variable "environment" {
  type        = string
  description = "利用環境（dev, stg, prodなど）"
}

# VPC
variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

# リソース名のプレフィックスに使用
variable "project_name" {
  type        = string
  description = "リソース名のプレフィックスとして使用するプロジェクト名"
  default     = "aws-ops-practice"
}

# ECS用
variable "container_port" {
  type        = number
  description = "ECSコンテナが受け付けるポート番号"
  default     = 80 # 仮イメージ(nginx)は80番ポート。後で自作アプリに合わせて変更可
}

# DBポート
variable "db_port" {
  type        = number
  description = "RDSが受け付けるポート番号"
  default     = 5432 # PostgreSQLの場合。MySQLなら3306に変更
}

variable "db_username" {
  type        = string
  description = "RDSのマスターユーザー名"
  default     = "appadmin"
}

