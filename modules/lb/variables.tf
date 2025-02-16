/**
 * ALBモジュールの変数定義 (object型)
 *
 * この変数は、ALBの設定に必要なすべての項目をひとまとめにしたobject型です。
 *
 * 設定内容:
 * - name: ALBの名称
 * - vpc_id: ALBを配置するVPCのID（networkモジュールで作成したVPCの出力値を利用）
 * - public_subnet_ids: ALBを配置するパブリックサブネットのIDリスト（networkモジュールの出力値）
 * - allow_http: HTTP(80)リスナーを作成するかどうかのフラグ
 * - allow_https: HTTPS(443)リスナーを作成するかどうかのフラグ
 * - certificate_arn: HTTPS用のACM証明書ARN（空の場合はHTTPSリスナー作成をスキップ）
 * - ingress_cidr_blocks_http: HTTP(80)を許可するインバウンドCIDRのリスト
 * - ingress_cidr_blocks_https: HTTPS(443)を許可するインバウンドCIDRのリスト
 *
 * - front_target_group: フロントエンドECS向けターゲットグループの設定
 *    - name: ターゲットグループの名称
 *    - port: ターゲットグループで使用するポート番号
 *    - health_check_path: ヘルスチェック用のパス
 *
 * - back_target_group: バックエンドECS向けターゲットグループの設定
 *    - name: ターゲットグループの名称
 *    - port: ターゲットグループで使用するポート番号
 *    - health_check_path: ヘルスチェック用のパス
 *
 * @see main.tf  ALBモジュールのリソース定義で使用
 */
variable "alb_config" {
  type = object({
    name                      = string               // ALBの名称
    vpc_id                    = string               // 配置先のVPC ID（networkモジュールから取得）
    public_subnet_ids         = list(string)         // ALBを配置するパブリックサブネットIDのリスト（networkモジュールから取得）
    allow_http                = bool                 // HTTP(80)リスナー作成の有無
    allow_https               = bool                 // HTTPS(443)リスナー作成の有無
    certificate_arn           = optional(string, "") // HTTPS用証明書ARN（未設定の場合は空文字）
    ingress_cidr_blocks_http  = list(string)         // HTTPリスナーで許可するインバウンドCIDRのリスト
    ingress_cidr_blocks_https = list(string)         // HTTPSリスナーで許可するインバウンドCIDRのリスト

    // フロントエンド用ターゲットグループ設定
    front_target_group = object({
      name              = string // ターゲットグループの名称
      port              = number // リスニングポート
      health_check_path = string // ヘルスチェック用パス
    })

    // バックエンド用ターゲットグループ設定
    back_target_group = object({
      name              = string // ターゲットグループの名称
      port              = number // リスニングポート
      health_check_path = string // ヘルスチェック用パス
    })
  })

}
