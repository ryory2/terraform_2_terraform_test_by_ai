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

# us-east-1用プロバイダー（CloudFront用の証明書はus-east-1に発行）
provider "aws" {
  alias  = "us_east"
  region = "us-east-1"
}
