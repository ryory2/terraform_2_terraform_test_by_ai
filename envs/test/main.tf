
resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.this.id
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"
  # map_public_ip_on_launch = true
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
  cidr_block        = "10.0.3.0/24"
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

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-1c"
  # map_public_ip_on_launch = true
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

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
    subnets          = [aws_subnet.private.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
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
