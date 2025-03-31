
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
  # execution_role_arn       = "arn:aws:iam::990606419933:role/ecsTaskExecutionRole"
  # task_role_arn      = "arn:aws:iam::990606419933:role/ecsTackRole"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn # 修正: 実行ロール
  task_role_arn      = aws_iam_role.ecs_task_role.arn           # 修正: タスクロール


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
        interval    = 30 # チェック間隔：30秒ごとに実行
        timeout     = 5  # 各チェックに対して5秒以内に完了することを要求
        retries     = 3  # 3回連続で失敗したら不健康と判断
        startPeriod = 10 # コンテナ起動後、10秒間はチェックをスキップ（猶予期間）
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

  enable_execute_command = true

  depends_on = [aws_lb_target_group.back_tg,
    aws_ecs_task_definition.main,
    aws_service_discovery_private_dns_namespace.this
  ]
}

#############################
# ACM証明書のリクエスト (us-east-1)
#############################
resource "aws_acm_certificate" "cert" {
  provider          = aws.us_east
  domain_name       = "impierrot.click"
  validation_method = "DNS"
  # ワイルドカード証明書の場合は以下を設定
  #   subject_alternative_names = ["*.impierrot.click"]
}

#############################
# Route53のホストゾーンのデータ取得
#############################
data "aws_route53_zone" "primary" {
  zone_id      = "Z06442292XEXGMHMQLXK9"
  name         = "impierrot.click."
  private_zone = false
}

#############################
# DNS検証用レコードの作成
#############################
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.primary.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

#############################
# 証明書検証の完了
#############################
resource "aws_acm_certificate_validation" "cert_validation" {
  provider                = aws.us_east
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

#############################
# 出力: 証明書ARN
#############################
output "acm_certificate_arn" {
  value = aws_acm_certificate_validation.cert_validation.certificate_arn
}

# resource "aws_route53_zone" "main" {
#   name = "impierrot.click"
# }

resource "aws_route53_record" "alias_cf" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "impierrot.click"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.react_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.react_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}

################################################################
# 1. S3バケット (Reactビルド成果物置き場)
################################################################
resource "aws_s3_bucket" "react_app_bucket" {
  bucket        = "my-react-spa-bucket-example-2023" # 一意の名前にする
  acl           = "private"                          # デフォルトのバケットポリシーは全てのアクセスを拒否する
  force_destroy = true
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
    "impierrot.click"
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
    acm_certificate_arn      = aws_acm_certificate_validation.cert_validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  depends_on = [aws_cloudfront_origin_access_identity.oai, aws_acm_certificate_validation.cert_validation]

  tags = {
    ManagedBy   = "Terraform"
    Environment = "Production"
  }
}


###############################################################################
# GitHub Actions 用 oidcプロバイダ (GitHub ActionsのOIDC認証)
###############################################################################

# GitHub OIDC Provider
resource "aws_iam_openid_connect_provider" "github" { # GitHubの公開鍵証明書のフィンガープリント
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["d89e3bd43d5d909b47a18977aa9d5ce36cee184c"]
}

###############################################################################
# GitHub Actions 用 IAMロール
###############################################################################

# IAMロール
resource "aws_iam_role" "github_actions" {
  name = "github_actions_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Sid" : "Statement1",
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "arn:aws:iam::990606419933:oidc-provider/token.actions.githubusercontent.com"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
          },
          "StringLike" : {
            "token.actions.githubusercontent.com:sub" : "repo:ryory2/*:*"
          }
        }
      }
    ]
  })
}


###############################################################################
# GitHub Actions 用 IAMポリシー (ECSタスク定義の更新、デプロイに必要な権限)
###############################################################################

# IAMポリシー (ECSタスク定義の更新、デプロイに必要な権限)
resource "aws_iam_policy" "github_actions_policy_to_deploy_to_ecs" {
  name        = "github-actions-policy-to-deploy-to-ecs"
  description = "Permissions for GitHub Actions to deploy to ECS"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "ecr:*",
          "cloudtrail:LookupEvents"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "iam:CreateServiceLinkedRole"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "iam:AWSServiceName" : [
              "replication.ecr.amazonaws.com"
            ]
          }
        }
      },
      {
        "Sid" : "ECSIntegrationsManagementPolicy",
        "Effect" : "Allow",
        "Action" : [
          "application-autoscaling:DeleteScalingPolicy",
          "application-autoscaling:DeregisterScalableTarget",
          "application-autoscaling:DescribeScalableTargets",
          "application-autoscaling:DescribeScalingActivities",
          "application-autoscaling:DescribeScalingPolicies",
          "application-autoscaling:PutScalingPolicy",
          "application-autoscaling:RegisterScalableTarget",
          "appmesh:DescribeVirtualGateway",
          "appmesh:DescribeVirtualNode",
          "appmesh:ListMeshes",
          "appmesh:ListVirtualGateways",
          "appmesh:ListVirtualNodes",
          "autoscaling:CreateAutoScalingGroup",
          "autoscaling:CreateLaunchConfiguration",
          "autoscaling:DeleteAutoScalingGroup",
          "autoscaling:DeleteLaunchConfiguration",
          "autoscaling:Describe*",
          "autoscaling:UpdateAutoScalingGroup",
          "cloudformation:CreateStack",
          "cloudformation:DeleteStack",
          "cloudformation:DescribeStack*",
          "cloudformation:UpdateStack",
          "cloudwatch:DeleteAlarms",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:PutMetricAlarm",
          "codedeploy:BatchGetApplicationRevisions",
          "codedeploy:BatchGetApplications",
          "codedeploy:BatchGetDeploymentGroups",
          "codedeploy:BatchGetDeployments",
          "codedeploy:ContinueDeployment",
          "codedeploy:CreateApplication",
          "codedeploy:CreateDeployment",
          "codedeploy:CreateDeploymentGroup",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:GetDeploymentGroup",
          "codedeploy:GetDeploymentTarget",
          "codedeploy:ListApplicationRevisions",
          "codedeploy:ListApplications",
          "codedeploy:ListDeploymentConfigs",
          "codedeploy:ListDeploymentGroups",
          "codedeploy:ListDeployments",
          "codedeploy:ListDeploymentTargets",
          "codedeploy:RegisterApplicationRevision",
          "codedeploy:StopDeployment",
          "ec2:AssociateRouteTable",
          "ec2:AttachInternetGateway",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:CancelSpotFleetRequests",
          "ec2:CreateInternetGateway",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateRoute",
          "ec2:CreateRouteTable",
          "ec2:CreateSecurityGroup",
          "ec2:CreateSubnet",
          "ec2:CreateVpc",
          "ec2:DeleteLaunchTemplate",
          "ec2:DeleteSubnet",
          "ec2:DeleteVpc",
          "ec2:Describe*",
          "ec2:DetachInternetGateway",
          "ec2:DisassociateRouteTable",
          "ec2:ModifySubnetAttribute",
          "ec2:ModifyVpcAttribute",
          "ec2:RequestSpotFleet",
          "ec2:RunInstances",
          "ecs:*",
          "elasticfilesystem:DescribeAccessPoints",
          "elasticfilesystem:DescribeFileSystems",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:DeleteRule",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "events:DeleteRule",
          "events:DescribeRule",
          "events:ListRuleNamesByTarget",
          "events:ListTargetsByRule",
          "events:PutRule",
          "events:PutTargets",
          "events:RemoveTargets",
          "fsx:DescribeFileSystems",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfiles",
          "iam:ListRoles",
          "lambda:ListFunctions",
          "logs:CreateLogGroup",
          "logs:DescribeLogGroups",
          "logs:FilterLogEvents",
          "route53:CreateHostedZone",
          "route53:DeleteHostedZone",
          "route53:GetHealthCheck",
          "route53:GetHostedZone",
          "route53:ListHostedZonesByName",
          "servicediscovery:CreatePrivateDnsNamespace",
          "servicediscovery:CreateService",
          "servicediscovery:DeleteService",
          "servicediscovery:GetNamespace",
          "servicediscovery:GetOperation",
          "servicediscovery:GetService",
          "servicediscovery:ListNamespaces",
          "servicediscovery:ListServices",
          "servicediscovery:UpdateService",
          "sns:ListTopics"
        ],
        "Resource" : [
          "*"
        ]
      },
      {
        "Sid" : "SSMPolicy",
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        "Resource" : "arn:aws:ssm:*:*:parameter/aws/service/ecs*"
      },
      {
        "Sid" : "ManagedCloudformationResourcesCleanupPolicy",
        "Effect" : "Allow",
        "Action" : [
          "ec2:DeleteInternetGateway",
          "ec2:DeleteRoute",
          "ec2:DeleteRouteTable",
          "ec2:DeleteSecurityGroup"
        ],
        "Resource" : [
          "*"
        ],
        "Condition" : {
          "StringLike" : {
            "ec2:ResourceTag/aws:cloudformation:stack-name" : "EC2ContainerService-*"
          }
        }
      },
      {
        "Sid" : "TasksPassRolePolicy",
        "Action" : "iam:PassRole",
        "Effect" : "Allow",
        "Resource" : [
          "*"
        ],
        "Condition" : {
          "StringLike" : {
            "iam:PassedToService" : "ecs-tasks.amazonaws.com"
          }
        }
      },
      {
        "Sid" : "InfrastructurePassRolePolicy",
        "Action" : "iam:PassRole",
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:iam::*:role/ecsInfrastructureRole"
        ],
        "Condition" : {
          "StringEquals" : {
            "iam:PassedToService" : "ecs.amazonaws.com"
          }
        }
      },
      {
        "Sid" : "InstancePassRolePolicy",
        "Action" : "iam:PassRole",
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:iam::*:role/ecsInstanceRole*"
        ],
        "Condition" : {
          "StringLike" : {
            "iam:PassedToService" : [
              "ec2.amazonaws.com",
              "ec2.amazonaws.com.cn"
            ]
          }
        }
      },
      {
        "Sid" : "AutoScalingPassRolePolicy",
        "Action" : "iam:PassRole",
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:iam::*:role/ecsAutoscaleRole*"
        ],
        "Condition" : {
          "StringLike" : {
            "iam:PassedToService" : [
              "application-autoscaling.amazonaws.com",
              "application-autoscaling.amazonaws.com.cn"
            ]
          }
        }
      },
      {
        "Sid" : "ServiceLinkedRoleCreationPolicy",
        "Effect" : "Allow",
        "Action" : "iam:CreateServiceLinkedRole",
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "iam:AWSServiceName" : [
              "ecs.amazonaws.com",
              "autoscaling.amazonaws.com",
              "ecs.application-autoscaling.amazonaws.com",
              "spot.amazonaws.com",
              "spotfleet.amazonaws.com"
            ]
          }
        }
      },
      {
        "Sid" : "ELBTaggingPolicy",
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:AddTags"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "elasticloadbalancing:CreateAction" : [
              "CreateTargetGroup",
              "CreateRule",
              "CreateListener",
              "CreateLoadBalancer"
            ]
          }
        }
      }
    ]
  })
}

# IAMロールにポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "github_actions_policy_attachment_to_deploy_to_ecs" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_policy_to_deploy_to_ecs.arn
}

###############################################################################
# GitHub Actions 用 IAMポリシー (S3 & CloudFront権限)
###############################################################################

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
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_policy.arn
}



###############################################################################
# ECSタスク実行ロール (Task Execution Role) & ECSタスクロール (Task Role)
###############################################################################
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}
# ECSタスク実行ロールにECSタスク実行に必要なポリシーをアタッチ (例: ECRへのアクセス)
resource "aws_iam_policy_attachment" "ecs_task_execution_role_attachment" {
  name       = "ecs-task-execution-role-attachment"
  roles      = [aws_iam_role.ecs_task_execution_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy" # AWS管理ポリシー
}


###############################################################################
# ECSタスク実行ロール (Task Execution Role) ポリシー
###############################################################################
resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

###############################################################################
# ECSタスク実行ロール (Task Execution Role) ポリシー
###############################################################################
# github_actions_policy_to_deploy_to_ecs ポリシーをタスクロールにアタッチ
resource "aws_iam_role_policy_attachment" "ecs_task_role_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.github_actions_policy_to_deploy_to_ecs.arn
}

###############################################################################
# CloudFront用IAMポリシー (CloudFrontのキャッシュ無効化権限)
###############################################################################
resource "aws_iam_policy" "cloudfront_policy" {
  name        = "CloudFrontPermissionsPolicy"
  description = "Permissions for CloudFront"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "cloudfront:CreateInvalidation"
        ],
        # 特定のディストリビューションに限定する場合
        # "Resource" : "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${var.cloudfront_distribution_id}"
        # すべてのディストリビューションを許可する場合 (非推奨)
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "cloudfront:GetDistribution",
          "cloudfront:ListDistributions"
        ],
        "Resource" : "*"
      }
    ]
  })
}

# IAMポリシーをロールにアタッチ
resource "aws_iam_role_policy_attachment" "cloudfront_policy_attachment" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.cloudfront_policy.arn
}
