/**
 * コンピュートモジュールで出力する値
 */
output "instance_id" {
  description = "EC2インスタンスのID"
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "EC2インスタンスのパブリックIP"
  value       = aws_instance.this.public_ip
}
