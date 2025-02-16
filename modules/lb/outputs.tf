/**
 * ALBモジュールの出力
 */
output "alb_arn" {
  description = "ALBのARN"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "ALBのDNS名 (例: my-alb-12345.ap-northeast-1.elb.amazonaws.com)"
  value       = aws_lb.this.dns_name
}

output "alb_sg_id" {
  description = "ALB用セキュリティグループID"
  value       = aws_security_group.alb_sg.id
}

output "front_tg_arn" {
  description = "フロント用ターゲットグループARN"
  value       = aws_lb_target_group.front_tg.arn
}

output "back_tg_arn" {
  description = "バックエンド用ターゲットグループARN"
  value       = aws_lb_target_group.back_tg.arn
}
