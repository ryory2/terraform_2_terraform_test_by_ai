/**
 * ネットワークモジュールで使用する変数定義
 */
# variable "vpc_cidr" {
#   type        = string
#   description = "VPCのCIDRブロック"
# }

# variable "public_subnet_cidrs" {
#   type        = list(string)
#   description = "サブネットのCIDRブロックリスト"
# }

# variable "public_availability_zones" {
#   type        = list(string)
#   description = "サブネットを配置するAZのリスト"
# }

# variable "private_subnet_cidrs" {
#   type        = list(string)
#   description = "サブネットのCIDRブロックリスト"
#   default     = [] // 値が指定されなければプライベートサブネットは作成されない
# }

# variable "private_availability_zones" {
#   type        = list(string)
#   description = "サブネットを配置するAZのリスト"
#   default     = [] // 値が指定されなければプライベートサブネットは作成されない
# }

variable "tags" {
  type        = map(string)
  default     = {}
  description = "VPCに付与するタグ"
}

# variable "enable_private_subnets" {
#   type    = bool
#   default = false
# }


variable "vpc_config" {
  description = "VPCおよびサブネットの設定(呼び出し元から受け取る)"
  type = object({
    vpc_cidr                   = string
    public_subnet_cidrs        = list(string)
    public_availability_zones  = list(string)
    enable_private_subnets     = bool
    private_subnet_cidrs       = list(string)
    private_availability_zones = list(string)
  })
}
