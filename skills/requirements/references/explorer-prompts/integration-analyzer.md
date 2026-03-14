# Integration Analyzer

Brownfield プロジェクトの外部連携・インフラ構成・非機能要件を分析するエージェント。
`/requirements` Step 1（brownfield モード）で起動される。

## 入力

- プロジェクトルートパス
- ソースコードディレクトリパス（src/, cmd/, app/ 等の自動検出結果）

## 分析手順

```
1. 外部 API 連携の検出:
   - fetch / axios / got / ky 等の HTTP クライアント呼び出しを検索
   - 外部 API の URL パターンを抽出（api.stripe.com, graph.facebook.com 等）
   - SDK インポートの検出（@stripe/stripe-js, @aws-sdk/*, firebase 等）
   - 環境変数から API キー・エンドポイントを推定
     （.env.example, .env.local.example, 設定ファイル）

2. データベース接続の検出:
   - DB ドライバ/ORM の接続設定
   - 接続文字列パターン（DATABASE_URL 等）
   - マイグレーションファイルの存在（prisma/migrations/, drizzle/ 等）
   - シード・フィクスチャの存在

3. 認証・認可の検出:
   - 認証ミドルウェアの存在
   - JWT / セッション / OAuth の使用パターン
   - 外部認証プロバイダ（Auth0, Firebase Auth, Supabase Auth 等）
   - RBAC / ABAC パターンの有無

4. メッセージング・キューの検出:
   - Redis, RabbitMQ, SQS, Pub/Sub 等のインポート
   - WebSocket の使用（ws, socket.io 等）
   - Server-Sent Events の使用

5. ファイルストレージの検出:
   - S3, GCS, Azure Blob のインポート
   - ローカルファイルシステムへの書き込みパターン
   - アップロード処理の存在（multer 等）

6. 環境変数の収集:
   - .env.example / .env.local.example を読み込み
   - process.env.XXX の参照パターンを検索
   - 必須環境変数と用途の推定

7. 非機能要件の推定:
   - レート制限の実装（rate-limit, throttle）
   - キャッシュの実装（Redis, in-memory, CDN）
   - ログ・監視の実装（winston, pino, sentry, datadog）
   - ヘルスチェックエンドポイントの存在
   - CORS 設定
   - セキュリティヘッダ（helmet 等）
```

## 出力フォーマット

```markdown
## 外部連携・NFR 分析結果

### 外部 API 連携
| サービス | 用途 | SDK/クライアント | 環境変数 |
|---------|------|----------------|---------|
| {Stripe} | {決済} | {@stripe/stripe-js} | {STRIPE_SECRET_KEY} |

### データベース
- DB: {PostgreSQL / MySQL / SQLite / MongoDB}
- 接続方式: {ORM 名 or ドライバ名}
- マイグレーション: {あり / なし}

### 認証・認可
- 方式: {JWT / セッション / OAuth / 外部プロバイダ}
- プロバイダ: {Auth0 / Firebase Auth / 自前 / なし}
- 権限モデル: {RBAC / なし}

### メッセージング
- キュー: {Redis / SQS / なし}
- リアルタイム: {WebSocket / SSE / なし}

### ファイルストレージ
- ストレージ: {S3 / GCS / ローカル / なし}

### 環境変数一覧
| 変数名 | 用途（推定） | 必須 |
|--------|------------|------|
| {DATABASE_URL} | {DB 接続} | {○} |

### 非機能要件（推定）
| カテゴリ | 実装状況 | 詳細 |
|---------|---------|------|
| レート制限 | {あり / なし} | {ライブラリ名} |
| キャッシュ | {あり / なし} | {Redis / in-memory} |
| ログ | {あり / なし} | {winston / pino} |
| 監視 | {あり / なし} | {Sentry / Datadog} |
| セキュリティ | {あり / なし} | {helmet / CORS 設定} |
```
