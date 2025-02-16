module "network" {
  source = "../../modules/network" # モジュールのパス
  // object型変数をまとめて渡す
  vpc_config = var.vpc_config
}
# module "front_end" {
#   source       = "../../modules/front_end/" # モジュールのパス
#   project_name = var.project_name
# }

module "alb" {
  source = "../../modules/lb"

  alb_config = {
    name                      = "my-alb"
    vpc_id                    = module.network.vpc_id
    public_subnet_ids         = module.network.public_subnet_ids
    allow_http                = true
    allow_https               = false
    certificate_arn           = ""
    ingress_cidr_blocks_http  = ["0.0.0.0/0"]
    ingress_cidr_blocks_https = ["0.0.0.0/0"]
    front_target_group = {
      name              = "front-tg"
      port              = 80
      health_check_path = "/"
    }
    back_target_group = {
      name              = "back-tg"
      port              = 8080
      health_check_path = "/health"
    }
  }
}
