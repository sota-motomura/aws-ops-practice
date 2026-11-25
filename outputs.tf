output "alb_dns_name" {
  description = "ALBのDNS名。ブラウザでアクセスして動作確認する"
  value       = aws_lb.main.dns_name
}