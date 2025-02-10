variable "global_tags" {
  type = map(string)
  default = {
    Tags = "not_set"
  }
}

variable "project_name" {
  type        = string
  default     = "project_name_default"
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
