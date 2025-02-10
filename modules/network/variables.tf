/**
 * ネットワークモジュールで使用する変数定義
 */
variable "vpc_cidr" {
  type        = string
  description = "VPCのCIDRブロック"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "サブネットのCIDRブロックリスト"
}

variable "public_availability_zones" {
  type        = list(string)
  description = "サブネットを配置するAZのリスト"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "サブネットのCIDRブロックリスト"
  default     = [] // 値が指定されなければプライベートサブネットは作成されない
}

variable "private_availability_zones" {
  type        = list(string)
  description = "サブネットを配置するAZのリスト"
  default     = [] // 値が指定されなければプライベートサブネットは作成されない
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "VPCに付与するタグ"
}
