/**
 * ネットワークモジュールで使用する変数定義
 */
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
