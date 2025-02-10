output "vpc_id" {
  value = aws_vpc.this.id
}
output "public_subnet_ids" {
  value = [for subnet in aws_subnet.public : subnet.id]
}
output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}
