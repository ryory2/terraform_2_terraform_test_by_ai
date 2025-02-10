module "network" {
  source = "../../modules/network" # モジュールのパス
  // object型変数をまとめて渡す
  vpc_config = var.vpc_config
  tags = {
    Name = var.global_tags_name //全体で使うタグ
  }
}
