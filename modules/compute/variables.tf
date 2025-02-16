/**
 * コンピュートモジュールで使用する変数定義
 */
# variable "project_name" {
#   type        = string
#   description = "プロジェクト名。タグ付けなどに使用"
# }

variable "ami_id" {
  type        = string
  description = "EC2インスタンスに使用するAMI ID"
}

variable "instance_type" {
  type        = string
  description = "EC2インスタンスタイプ (例: t2.micro)"
  default     = "t2.micro"
}

variable "subnet_id" {
  type        = string
  description = "EC2インスタンスを配置するサブネットのID"
}

variable "security_group_ids" {
  type        = list(string)
  description = "EC2インスタンスに適用するセキュリティグループIDのリスト"
}
