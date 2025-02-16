/**
 * コンピュートモジュール
 *
 * このモジュールではEC2インスタンスやECSクラスターなど
 * コンピュートリソースをまとめて管理します。
 */
# 変数:
#   
#   
#   
#   
#   
#   
#
# 出力:
#   
#   
#   

# ECSクラスタの作成
#
# このリソースは、ECS (Elastic Container Service) クラスタを作成します。
# ECSクラスタは、コンテナ化されたアプリケーションを実行するための基盤となります。
#
# @param name クラスタの名前 (必須)。一意の名前を指定してください。
# @param setting ContainerInsightsの設定 (オプション)。デフォルトでは有効になっています。
# @param tags クラスタに付与するタグ (オプション)。キーと値のペアで指定します。
# @see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster
resource "aws_ecs_cluster" "this" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# サービスディスカバリーの名前空間
#
# このリソースは、サービスディスカバリーのプライベートDNS名前空間を作成します。
# ECSサービスは、この名前空間を使用して他のサービスを検出できます。
#
# @param name 名前空間の名前 (必須)。一意の名前を指定してください。
# @param description 名前空間の説明 (オプション)。
# @param vpc VPC ID (必須)。名前空間を作成するVPCのIDを指定してください。
resource "aws_service_discovery_private_dns_namespace" "this" {
  name        = var.service_discovery_name
  description = "Service Discovery Namespace"
  vpc         = var.vpc_id
}

# ECSタスク定義の作成
#
# このリソースは、ECSタスク定義を作成します。
# タスク定義は、コンテナの起動方法やリソース割り当てなどを定義します。
#
# @param family タスク定義のfamily (必須)。一意のfamily名を指定してください。
# @param network_mode ネットワークモード (必須)。Fargateでは "awsvpc" を指定します。
# @param requires_compatibilities 必要な互換性 (必須)。Fargateでは ["FARGATE"] を指定します。
# @param cpu タスクに割り当てるCPUユニット数 (必須)。例: "256" (0.25 vCPU)。
# @param memory タスクに割り当てるメモリ量 (必須)。例: "512" (0.5 GB)。
# @param execution_role_arn ECSタスク実行ロールのARN (必須)。コンテナがAWSリソースにアクセスするために必要なIAMロールのARNを指定します。
# @param task_role_arn ECSタスクロールのARN (必須)。タスク自身がAWSリソースにアクセスするために必要なIAMロールのARNを指定します。
# @param container_definitions コンテナ定義のJSON (必須)。コンテナの設定をJSON形式で指定します。
resource "aws_ecs_task_definition" "main" {
  family                   = var.task_definition_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn
  container_definitions    = jsonencode(var.container_definitions)
  #   container_definitions = jsonencode([
  #   {
  #     name      = "backend"
  #     image     = var.container_image
  #     cpu       = var.task_cpu
  #     memory    = var.task_memory
  #     essential = true
  #     portMappings = [
  #       {
  #         containerPort = var.container_port
  #         hostPort      = var.container_port
  #       }
  #     ]
  #   }
  # ])
}
