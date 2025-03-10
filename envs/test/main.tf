
resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.this.id
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "public2" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-1c"
  # map_public2_ip_on_launch = true
}

resource "aws_route_table" "public2" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route" "public2" {
  route_table_id         = aws_route_table.public2.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public2.id
}

# resource "aws_subnet" "private" {
#   vpc_id            = aws_vpc.this.id
#   cidr_block        = "10.0.2.0/24"
#   availability_zone = "ap-northeast-1c"
#   # map_public_ip_on_launch = true
# }

# resource "aws_route_table" "private" {
#   vpc_id = aws_vpc.this.id
# }

# resource "aws_route" "private" {
#   route_table_id         = aws_route_table.private.id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.gw.id
# }

# resource "aws_route_table_association" "private" {
#   subnet_id      = aws_subnet.private.id
#   route_table_id = aws_route_table.private.id
# }

resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = aws_vpc.this.id
  /**
   * HTTP(80)のインバウンドルール
   * - allow_httpがtrueの場合、指定したCIDRブロックからの80番ポートアクセスを許可
   */
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  /**
   * HTTPS(443)のインバウンドルール
   * - allow_httpsがtrueの場合、指定したCIDRブロックからの443番ポートアクセスを許可
   */
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  /**
   * HTTP(8080)のインバウンドルール
   * - allow_httpがtrueの場合、指定したCIDRブロックからの80番ポートアクセスを許可
   */
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  /**
   * 全てのアウトバウンドトラフィックを許可するルール
   */
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_sg" {
  name        = "ecs-service-sg"
  description = "Allow inbound 8080 from ALB"
  vpc_id      = aws_vpc.this.id

  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.alb_sg.id] //ALBセキュリティグループからの通信のみを許可
    description     = "Allow 443 from ALB"
  }
  ingress {
    protocol        = "tcp"
    from_port       = 443
    to_port         = 443
    security_groups = [aws_security_group.alb_sg.id] //ALBセキュリティグループからの通信のみを許可
    description     = "Allow 443 from ALB"
  }
  # ALBからの8080を許可
  ingress {
    protocol        = "tcp"                          //tcp、udp、または -1（すべてのプロトコル）
    from_port       = 8080                           //許可するポート範囲の開始
    to_port         = 8080                           //許可するポート範囲の終了
    security_groups = [aws_security_group.alb_sg.id] //ALBセキュリティグループからの通信のみを許可
    description     = "Allow 8080 from ALB"
  }

  egress {
    protocol    = "-1" //tcp、udp、または -1（すべてのプロトコル）
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"] //アウトバウンド通信の許可先
  }
}

resource "aws_lb" "this" {
  name               = "alb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public.id, aws_subnet.public2.id]
  security_groups    = [aws_security_group.alb_sg.id]
}

# resource "aws_lb_listener" "http_listener" {
#   load_balancer_arn = aws_lb.this.arn
#   port              = 80
#   protocol          = "HTTP"
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.front_tg.arn
#   }
# }

# resource "aws_lb_listener" "https_listener" {
#   load_balancer_arn = aws_lb.this.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = ""
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.back_tg.arn
#   }
# }

resource "aws_lb_listener" "backend_listener" {
  load_balancer_arn = aws_lb.this.arn
  port              = 8080
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.back_tg.arn
  }
}

resource "aws_lb_target_group" "front_tg" {
  name        = "front-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.this.id
  target_type = "ip"
  health_check {
    path = "/"
  }
}

resource "aws_lb_target_group" "back_tg" {
  name        = "back-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.this.id
  target_type = "ip"
  health_check {
    healthy_threshold   = 3
    interval            = 10
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }
}

resource "aws_ecs_cluster" "this" {
  name = "my-ecs-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_service_discovery_private_dns_namespace" "this" {
  name = "my-ecs-sd-namespace"
  vpc  = aws_vpc.this.id
}

resource "aws_service_discovery_service" "my_service" {
  name = "my-sd-service"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.this.id

    dns_records {
      type = "A"
      ttl  = 300
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ecs_task_definition" "main" {
  family                   = "my-task-family"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::990606419933:role/ecsTaskExecutionRole"
  task_role_arn            = "arn:aws:iam::990606419933:role/ecsTackRole"

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "990606419933.dkr.ecr.ap-northeast-1.amazonaws.com/test/go_1_test_repository:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }
    }
  ])
}

resource "aws_ecs_service" "main" {
  name            = "myservice"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.back_tg.arn
    container_name   = "backend"
    container_port   = 8080
  }

  service_registries {
    registry_arn = aws_service_discovery_service.my_service.arn
    # port         = 8080\
  }

  depends_on = [aws_lb_target_group.back_tg,
    aws_ecs_task_definition.main,
    aws_service_discovery_private_dns_namespace.this
  ]
}
#
######################
# GitHub Actions用IAMユーザー
#######################
resource "aws_iam_user" "github_actions_deployer" {
  name          = "github-actions-deployer"
  force_destroy = true
}

resource "aws_iam_user_policy_attachment" "ecr_access" {
  user       = aws_iam_user.github_actions_deployer.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_user_policy_attachment" "ecs_access" {
  user       = aws_iam_user.github_actions_deployer.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}


# 各ステートメントを含むIAMポリシードキュメント
resource "aws_iam_policy" "ecs_task_deploy_policy" {
  name        = "ECSRegisterAndDeployPolicy"
  description = "Policy to allow registering ECS task definitions and updating ECS services"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "RegisterTaskDefinition",
        Effect = "Allow",
        Action = [
          "ecs:RegisterTaskDefinition"
        ],
        Resource = "*"
      },
      {
        Sid    = "PassRolesInTaskDefinition",
        Effect = "Allow",
        Action = [
          "iam:PassRole"
        ],
        Resource = [
          # 実際に使用しているロールARNに修正
          "arn:aws:iam::990606419933:role/ecsTaskRole",
          "arn:aws:iam::990606419933:role/ecsTaskExecutionRole"
        ]
      },
      {
        Sid    = "DeployService",
        Effect = "Allow",
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ],
        Resource = [
          # 実際のクラスター名・サービス名に合わせる
          "arn:aws:ecs:ap-northeast-1:990606419933:service/my-ecs-cluster/myservice"
        ]
      }
    ]
  })
}

# 作成したポリシーをGitHub Actions用IAMユーザにアタッチ
resource "aws_iam_user_policy_attachment" "deploy_policy_attach" {
  user       = aws_iam_user.github_actions_deployer.name
  policy_arn = aws_iam_policy.ecs_task_deploy_policy.arn
}

#######################
# GitHub Actions用: ECSデプロイに必要な iam:PassRole 権限を付与
#######################
resource "aws_iam_policy" "ecs_passrole_policy" {
  name        = "github-actions-deployer-ecs-passrole"
  description = "Allow GitHub Actions deployer to pass ECS task execution and task roles."
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "iam:PassRole",
        "Resource" : [
          "arn:aws:iam::990606419933:role/ecsTaskExecutionRole",
          "arn:aws:iam::990606419933:role/ecsTaskRole"
        ]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "ecs_passrole_attachment" {
  user       = aws_iam_user.github_actions_deployer.name
  policy_arn = aws_iam_policy.ecs_passrole_policy.arn
}

################################################################
# 1. S3バケット (Reactビルド成果物置き場)
################################################################
resource "aws_s3_bucket" "react_app_bucket" {
  bucket = "my-react-spa-bucket-example-2023" # 一意の名前にする
  acl    = "private"                          # デフォルトのバケットポリシーは全てのアクセスを拒否する
}

resource "aws_s3_bucket_public_access_block" "react_app_block" {
  bucket = aws_s3_bucket.react_app_bucket.id

  block_public_acls       = true # バケットACLによるパブリックアクセスを拒否
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

################################################################
# 2. CloudFrontのOrigin Access Identity(OAI) & バケットポリシー
################################################################
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for my React SPA"
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.react_app_bucket.arn}/*"
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "react_app_bucket_policy" {
  bucket = aws_s3_bucket.react_app_bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

################################################################
# 3. CloudFront Distribution
################################################################
resource "aws_cloudfront_distribution" "react_distribution" {
  enabled             = true
  default_root_object = "index.html"

  # カスタムドメインを指定
  aliases = [
    "impierrot.click",
    "www.impierrot.click"
  ]

  origin {
    domain_name = aws_s3_bucket.react_app_bucket.bucket_regional_domain_name
    origin_id   = "myS3Origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "myS3Origin"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # SPAのルーティング用に404をindex.htmlにフォールバックさせる例
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  # 必要に応じて独自ドメイン＆ACM証明書を設定
  viewer_certificate {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:990606419933:certificate/e84215c2-690d-4ad1-ad46-537afc0cba3c"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

################################################################
# 4. GitHub Actions用 OIDC プロバイダ
################################################################
# GitHubが提供するOIDCエンドポイントを登録
resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # GitHubの固定Thumbprint
}

################################################################
# 5. IAMロール (GitHub ActionsがAssumeする)
################################################################
# OIDCでGitHubリポジトリからのみAssumeRoleできるようポリシー条件を指定
data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    # Condition: 特定のリポジトリ、特定ブランチ(または任意のブランチ)を指定する
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:YourOrgName/YourRepoName:*"]
      # 例: "repo:YourOrgName/YourRepoName:ref:refs/heads/main" のようにブランチ縛りも可
    }
  }
}

resource "aws_iam_role" "github_actions_role" {
  name               = "GitHubActionsDeployRole"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json
}

################################################################
# 6. IAMロールに付与するポリシー(S3アップロード & CF無効化)
################################################################
data "aws_iam_policy_document" "github_actions_policy_doc" {
  statement {
    actions = [
      # S3へアップロードする
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.react_app_bucket.arn,
      "${aws_s3_bucket.react_app_bucket.arn}/*"
    ]
  }

  statement {
    actions = [
      # CloudFrontのキャッシュ無効化
      "cloudfront:CreateInvalidation"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "github_actions_policy" {
  name   = "GitHubActionsS3CloudFrontPolicy"
  policy = data.aws_iam_policy_document.github_actions_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  policy_arn = aws_iam_policy.github_actions_policy.arn
  role       = aws_iam_role.github_actions_role.name
}

################################################################
# 7. 出力
################################################################
output "s3_bucket_name" {
  description = "ビルド成果物をアップロードするS3バケット名"
  value       = aws_s3_bucket.react_app_bucket.bucket
}

output "cloudfront_distribution_id" {
  description = "CloudFrontのディストリビューションID (キャッシュ無効化時に使用)"
  value       = aws_cloudfront_distribution.react_distribution.id
}

output "cloudfront_domain_name" {
  description = "CloudFrontドメイン"
  value       = aws_cloudfront_distribution.react_distribution.domain_name
}

###############################################################################
# GitHub Actions IAMユーザーに S3 & CloudFront 権限を付与する
###############################################################################
resource "aws_iam_policy" "github_actions_s3_cf_user_policy" {
  name        = "GitHubActionsS3CloudFrontUserPolicy"
  description = "Allow S3 (Put/Delete/Get/List) & CloudFront invalidation for GitHub Actions user"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3Actions"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = [
          # バケットとそのオブジェクトを対象に設定
          aws_s3_bucket.react_app_bucket.arn,
          "${aws_s3_bucket.react_app_bucket.arn}/*"
        ]
      },
      {
        Sid    = "AllowCloudFrontInvalidation"
        Effect = "Allow"
        Action = "cloudfront:CreateInvalidation"
        # 必要に応じて特定のディストリビューションARNに変更可
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "github_actions_s3_cf_user_policy_attachment" {
  user       = aws_iam_user.github_actions_deployer.name
  policy_arn = aws_iam_policy.github_actions_s3_cf_user_policy.arn
}
