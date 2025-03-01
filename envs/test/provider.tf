#tag: env-dev

terraform {
  required_version = ">= 1.0.0"

  # ローカルステート管理 (Backend 設定なし)
  # stateファイルはローカルに保存される
}

provider "aws" {
  region  = "ap-northeast-1"
  profile = "default" # 必要に応じて切り替え
}
