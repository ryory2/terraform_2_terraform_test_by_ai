terraform {
  required_version = ">= 1.0.0"
}

provider "aws" {
  region  = "ap-northeast-1"
  profile = "default"
  default_tags {
    tags = var.global_tags
  }
}
