# VPCを作成するモジュール
#
# このモジュールは、VPCの作成、サブネットの作成、インターネットゲートウェイの作成、ルートテーブルの設定を行います。
#
# 変数:
#   vpc_cidr: VPCのCIDRブロック (必須)
#   public_subnet_cidrs: パブリックサブネットのCIDRブロックのリスト (必須)
#   public_availability_zones: パブリックサブネットを配置するAZのリスト (必須)
#   private_subnet_cidrs: サブネットのCIDRブロックのリスト (任意)
#   private_availability_zones: サブネットを配置するAZのリスト (任意)
#   tags: VPCに付与するタグ (オプション)
#
# 出力:
#   vpc_id: 作成されたVPCのID
#   private_subnet_ids: 作成されたプライベートサブネットのIDリスト
#   public_subnet_ids: 作成されたパブリックサブネットのIDリスト

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = merge({
    Name = "vpc-${var.tags.Name}"
    },
    var.tags
  )
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "igw-${var.tags.Name}"
  }
}

/**
 * パブリックサブネットを作成
 */
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.public_availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route" "public" {
  /**
   * すべてのトラフィックをインターネットゲートウェイに向けるルートを追加
   */
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public" {
  /**
   * パブリックサブネットをパブリックルートテーブルに関連付け
   */
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

/**
 * プライベートサブネットを作成
 */
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.private_availability_zones[count.index]

  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

resource "aws_route_table" "private_route_table" {
  count = length(var.private_subnet_cidrs) > 0 ? 1 : 0
  /**
 * プライベートサブネット用のルートテーブル
 * (例では NAT Gateway を使用しないためインターネットアクセスなし)
 * ※プライベートサブネットが指定されている場合のみ作成する
 */
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "private-route-table"
  }
}


resource "aws_route_table_association" "private_subnet_association" {
  /**
 * プライベートサブネットとルートテーブルの関連付け
 * ※プライベートサブネットがある場合のみ作成する
 */
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_route_table[0].id
}
