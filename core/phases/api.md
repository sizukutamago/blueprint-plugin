# Phase: API Design

API設計・外部システム連携仕様を作成するフェーズ。
RESTful API設計、エンドポイント定義、リクエスト/レスポンススキーマ、
外部サービス連携仕様の文書化を行う。

## Contract (YAML)

```yaml
phase_id: "5"
required_artifacts:
  - docs/requirements/user-stories.md
  - docs/04_data_structure/data_structure.md
  - decisions.entities   # Blackboard: Wave A で確定したエンティティ一覧

outputs:
  - path: docs/05_api_design/api_design.md
    required: true
  - path: docs/05_api_design/integration.md
    required: false   # 外部連携がある場合のみ

contract_outputs:
  - key: decisions.api_resources
    type: array
    description: "API リソース定義（id, path, methods, request_entity, response_entity）"
  - key: traceability.fr_to_api
    type: object
    description: "FR-ID → API-ID[] のマッピング"
  - key: traceability.api_to_ent
    type: object
    description: "API-ID → ENT-ID[] のマッピング"

quality_gates:
  - "全 FR-ID が最低1つの API にマッピングされていること"
  - "全 API に API-ID が採番されていること"
  - "リクエスト/レスポンスが既存エンティティと整合していること"
  - "RESTful 設計原則に準拠していること（URL 設計、HTTP メソッド選択）"
  - "エラーレスポンスが RFC 7807 形式であること"
```

## 入力要件

| 入力 | 必須 | 説明 |
|------|------|------|
| docs/requirements/user-stories.md | ○ | API 抽出元（機能要件、Gherkin 形式） |
| docs/04_data_structure/data_structure.md | ○ | リクエスト/レスポンス型の根拠 |
| decisions.entities（Blackboard） | ○ | Wave A で確定したエンティティ一覧 |

## 出力ファイル

| ファイル | 説明 |
|---------|------|
| docs/05_api_design/api_design.md | API 仕様書 |
| docs/05_api_design/integration.md | 外部システム連携仕様（該当する場合のみ） |

### api_design.md 必須セクション

1. 設計方針（設計原則、バージョニング、ベースURL）
2. 命名規則
3. 認証・認可
4. API 一覧（API-ID、メソッド、エンドポイント、概要、認証要否）
5. API 詳細（各 API のパラメータ、リクエスト/レスポンス、エラー）
6. 共通仕様（日時形式、ページネーション、レート制限）
7. エラーコード一覧

### integration.md 必須セクション（該当する場合のみ）

1. 連携システム一覧
2. 連携方式（同期API、非同期、Webhook、バッチ）
3. 連携先詳細（エンドポイント、認証、タイムアウト、リトライ）
4. 障害時対応（フォールバック）

## ワークフロー

```
1. 機能要件（user-stories.md）を読み込み
2. エンティティ定義（data_structure.md）を読み込み
3. 機能要件から必要な API を抽出
4. リソースを特定（RESTful 設計）
5. 各 API に API-ID を採番（API-XXX 形式、3桁ゼロパディング）
6. エンティティを使用してリクエスト/レスポンスを設計
7. エンドポイント・メソッドを決定
8. 認証・認可要件を定義
9. エラーレスポンスを RFC 7807 形式で設計
10. 外部連携がある場合は integration.md を生成
11. トレーサビリティ（FR→API、API→ENT）を作成
12. contract_outputs を出力
```

**重要**: このフェーズはエンティティ定義後、画面設計前に実行する。
エンティティを使用して API を設計し、画面は API を使用して設計する。

## ID 採番ルール

| 項目 | ルール |
|------|--------|
| 形式 | API-XXX（3桁ゼロパディング） |
| 開始 | 001 |

## RESTful 設計原則

### URL 設計

| パターン | 例 |
|---------|-----|
| コレクション | GET /products |
| 単一リソース | GET /products/{id} |
| 作成 | POST /products |
| 更新 | PUT /products/{id} |
| 削除 | DELETE /products/{id} |

### 命名規則

| 対象 | 規則 |
|------|------|
| エンドポイント | kebab-case、複数形 |
| クエリパラメータ | snake_case |
| JSON フィールド | camelCase |

## 認証・認可

| 方式 | 用途 |
|------|------|
| Bearer Token (JWT) | 一般的な API 認証 |
| API Key | サーバー間通信 |
| OAuth 2.0 | 外部サービス連携 |

## エラーレスポンス（RFC 7807）

```json
{
  "type": "https://api.example.com/errors/validation",
  "title": "Validation Error",
  "status": 400,
  "detail": "入力値が不正です"
}
```

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| user-stories 不在 | P0 報告、要件定義へ差し戻し |
| エンティティ不在 | P0 報告、database フェーズの実行を要請 |
| 未定義エンティティ参照 | P1 報告、database フェーズへ差し戻し提案 |
| FR に対応する API が定義できない | P2 報告、要件の明確化を要請 |
