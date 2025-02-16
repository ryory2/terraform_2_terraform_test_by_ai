/**
 * ALBモジュール
 *
 * このモジュールは以下のリソースを作成します。
 *  - ALB用のセキュリティグループ
 *  - Application Load Balancer本体
 *  - フロントエンド用ターゲットグループ
 *  - バックエンド用ターゲットグループ
 *  - HTTP(80)リスナー (allow_httpフラグがtrueの場合)
 *  - HTTPS(443)リスナー (allow_httpsフラグがtrueかつcertificate_arnが設定されている場合)
 *
 * ※ vpc_id および public_subnet_ids は、ネットワークモジュール（例：module.network）の出力値を利用します。
 *
 * @see var.alb_config  ALBの設定情報をまとめたobject型変数
 */

resource "aws_security_group" "alb_sg" {
  name        = "${var.alb_config.name}-sg"
  description = "security group for alb"
  vpc_id      = var.alb_config.vpc_id // ← この値は networkモジュール(module.network.vpc_id)から渡す
  /**
   * HTTP(80)のインバウンドルール
   * - allow_httpがtrueの場合、指定したCIDRブロックからの80番ポートアクセスを許可
   */
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.alb_config.allow_http ? var.alb_config.ingress_cidr_blocks_http : []
  }
  /**
   * HTTPS(443)のインバウンドルール
   * - allow_httpsがtrueの場合、指定したCIDRブロックからの443番ポートアクセスを許可
   */
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.alb_config.allow_https ? var.alb_config.ingress_cidr_blocks_https : []
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

/**
 * Application Load Balancer (ALB) の作成
 *
 * - networkモジュールで作成された VPC およびパブリックサブネット (module.network.public_subnet_ids)
 *   上に ALB を作成し、先ほど定義したセキュリティグループを適用します。
 */
resource "aws_lb" "this" {
  name               = var.alb_config.name
  load_balancer_type = "application"
  subnets            = var.alb_config.public_subnet_ids // ← networkモジュールから取得するサブネットIDリスト
  security_groups    = [aws_security_group.alb_sg.id]
}

/**
 * フロントエンド用ターゲットグループ
 *
 * - ALBからフロントエンドECSサービスへトラフィックを転送するためのターゲットグループ。
 * - Fargate環境を想定し、ターゲットタイプは「ip」としています。
 */
resource "aws_lb_target_group" "front_tg" {
  name        = var.alb_config.front_target_group.name
  port        = var.alb_config.front_target_group.port
  protocol    = "HTTP"
  vpc_id      = var.alb_config.vpc_id // networkモジュールのVPCを利用
  target_type = "ip"                  // Fargateを想定
  /**
   * ヘルスチェックの設定
   */
  health_check {
    path = var.alb_config.front_target_group.health_check_path
  }
}

/**
 * バックエンド用ターゲットグループ
 *
 * - ALBからバックエンドECSサービスへトラフィックを転送するためのターゲットグループ。
 * - Fargate環境を想定し、ターゲットタイプは「ip」としています。
 */
resource "aws_lb_target_group" "back_tg" {
  name        = var.alb_config.back_target_group.name
  port        = var.alb_config.back_target_group.port
  protocol    = "HTTP"
  vpc_id      = var.alb_config.vpc_id // networkモジュールから取得したVPC IDを使用
  target_type = "ip"
  /**
   * ヘルスチェックの設定
   */
  health_check {
    path = var.alb_config.back_target_group.health_check_path
  }
}

/**
 * HTTPリスナー(80)の作成
 *
 * - allow_httpフラグがtrueの場合のみ作成されます。
 * - デフォルトアクションとして、フロントエンド用ターゲットグループ(front_tg)に転送します。
 */
resource "aws_lb_listener" "http_listener" {
  count             = var.alb_config.allow_http ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_tg.arn
  }
}

/**
 * HTTPSリスナー(443)の作成
 *
 * - allow_httpsフラグがtrueかつcertificate_arnが設定されている場合のみ作成されます。
 * - SSLポリシーは ELBSecurityPolicy-2016-08 を使用しています。
 * - デフォルトアクションとして、バックエンド用ターゲットグループ(back_tg)に転送します。
 */
resource "aws_lb_listener" "https_listener" {
  count             = var.alb_config.allow_https && var.alb_config.certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.alb_config.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.back_tg.arn
  }
}
