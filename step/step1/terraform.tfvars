# 全Terraformリソースで使う共通タグをここにまとめる
project_name = "project_name_custom"

/**
 * 全リソースで使う共通タグをここにまとめる
 * 変数:
 * キー = タグ名
 */
global_tags = {
  Environment = "dev"
  #   Owner       = "prod-team"
}
/**
 * ネットワーク作成で使用する変数
 * 変数:
 * vpc_cidr: VPCのCIDRブロック (必須)
 * public_subnet_cidrs[string]: パブリックサブネットのCIDRブロックのリスト (必須)
 * public_availability_zones[list(string)]: パブリックサブネットを配置するAZのリスト (必須)
 * enable_private_subnets[bool]: プライベートサブネットを作成するかどうか (必須)
 * private_subnet_cidrs[list(string)]: サブネットのCIDRブロックのリスト (オプション)
 * private_availability_zones[list(string)]: サブネットを配置するAZのリスト (オプション)
 * tags: VPCに付与するタグ (必須)
 */
vpc_config = {
  vpc_cidr                   = "10.0.0.0/16"                          //（必須）VPCのCIDRブロック
  public_subnet_cidrs        = ["10.0.1.0/24", "10.0.2.0/24"]         //（必須）ciderのリスト。（必須）
  public_availability_zones  = ["ap-northeast-1a", "ap-northeast-1c"] //（必須）azのリスト。
  enable_private_subnets     = false                                  //（必須）boolean。プライベートサブネットを作成する場合はtrue
  private_subnet_cidrs       = ["10.0.3.0/24", "10.0.4.0/24"]         //（オプション）ciderのリスト。プライベートサブネット作成フラグがfalseの場合省略可
  private_availability_zones = ["ap-northeast-1a", "ap-northeast-1c"] //（オプション）azのリスト。プライベートサブネット作成フラグがfalseの場合省略可
}
