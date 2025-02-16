variable "global_tags" {
  type = map(string)
  default = {
    Tags = "not_set"
  }
}

variable "project_name" {
  type        = string
  default     = "project-name-default"
  description = "プロジェクト名"
}

// ネットワークに関する情報をここでひとまとめに定義
// 実際はterraform.tfvarsで値を設定すること
variable "vpc_config" {
  description = "VPCおよびサブネットの設定"
  type = object({
    vpc_cidr                   = string
    public_subnet_cidrs        = list(string)
    public_availability_zones  = list(string)
    enable_private_subnets     = bool
    private_subnet_cidrs       = list(string)
    private_availability_zones = list(string)
  })
  default = {
    vpc_cidr                   = "10.0.0.0/16"
    public_subnet_cidrs        = ["10.0.1.0/24", "10.0.2.0/24"]
    public_availability_zones  = ["ap-northeast-1a", "ap-northeast-1c"]
    enable_private_subnets     = false
    private_subnet_cidrs       = []
    private_availability_zones = []
  }
}

# /**
#  * ALBモジュールの変数定義 (object型)
#  * 
#  * 必要な要素をひとまとめにしたサンプルです。
#  * 例として、フロント用ターゲットグループとバックエンド用ターゲットグループを別々に作成する想定。
#  */
# variable "alb_config" {
#   type = object({
#     name                      = string               // ALBの名称
#     vpc_id                    = string               // 配置先のVPC
#     public_subnet_ids         = list(string)         // ALBを置くサブネット
#     allow_http                = bool                 // HTTP(80)リスナーを作るか
#     allow_https               = bool                 // HTTPS(443)リスナーを作るか
#     certificate_arn           = optional(string, "") // HTTPS用の証明書ARN(空文字の場合は作らない)
#     ingress_cidr_blocks_http  = list(string)         // HTTP許可元CIDR
#     ingress_cidr_blocks_https = list(string)         // HTTPS許可元CIDR

#     // ターゲットグループ設定 (シンプルな例)
#     front_target_group = object({
#       name              = string
#       port              = number
#       health_check_path = string
#     })

#     back_target_group = object({
#       name              = string
#       port              = number
#       health_check_path = string
#     })
#   })
#   description = <<EOT
# ALBの設定をまとめたobject。
# - name: ALB名
# - vpc_id: VPC ID
# - public_subnet_ids: ALBを配置するパブリックサブネットIDのリスト
# - allow_http: HTTPリスナー作成有無
# - allow_https: HTTPSリスナー作成有無
# - certificate_arn: HTTPS用のACM証明書ARN(空ならHTTPSリスナーをスキップ or 作れない)
# - ingress_cidr_blocks_http: HTTP(80)を許可するCIDRのリスト
# - ingress_cidr_blocks_https: HTTPS(443)を許可するCIDRのリスト
# - front_target_group: フロントECS向けターゲットグループ設定
# - back_target_group: バックエンドECS向けターゲットグループ設定
# EOT
# }
