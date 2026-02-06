---
name: api
description: This skill should be used when the user asks to "design API", "create REST endpoints", "document API specifications", "define API contracts", "plan external integrations", or "create OpenAPI spec". Designs RESTful APIs and external system integration specifications for Wave B parallel execution.
version: 2.0.0
model: sonnet
---

# API Skill

API設計・外部システム連携仕様を作成するスキル。
RESTful API設計、エンドポイント定義、リクエスト/レスポンススキーマ、
外部サービス連携仕様の文書化に使用する。

**実行タイミング**: Wave B（architecture-detail と並列、Wave A 完了後）

## 前提条件

| 条件 | 必須 | 説明 |
|------|------|------|
| docs/requirements/user-stories.md | ○ | API抽出元（web-requirements 出力） |
| docs/04_data_structure/data_structure.md | ○ | リクエスト/レスポンス型 |
| Blackboard: decisions.entities | ○ | Wave A で確定したエンティティ一覧 |

## 出力ファイル

| ファイル | テンプレート | 説明 |
|---------|-------------|------|
| docs/05_api_design/api_design.md | {baseDir}/references/api_design.md | API仕様 |
| docs/05_api_design/integration.md | {baseDir}/references/integration.md | 外部連携仕様 |

## 依存関係

| 種別 | 対象 |
|------|------|
| 前提スキル | web-requirements, database（Wave A） |
| 並列スキル | architecture-detail（Wave B） |
| 後続スキル | design-detail（post-B）, wave-aggregator |

## Wave B 契約出力

Blackboard に以下を登録する:

```yaml
contract_outputs:
  - key: decisions.api_resources
    value:
      - id: API-001
        path: /users
        methods: [GET, POST]
        request_entity: null
        response_entity: ENT-User
      - id: API-002
        path: /users/{id}
        methods: [GET, PUT, DELETE]
        request_entity: ENT-User
        response_entity: ENT-User
```

## ID採番ルール

| 項目 | ルール |
|------|--------|
| 形式 | API-XXX（3桁ゼロパディング） |
| 開始 | 001 |

## ワークフロー

```
1. 機能要件・エンティティ定義を読み込み
2. 機能要件から必要なAPIを抽出
3. エンティティを使用してリクエスト/レスポンスを設計
4. リソースを特定（RESTful設計）
5. 各APIにAPI-IDを採番
6. エンドポイント・メソッドを決定
7. 外部連携がある場合は integration.md を生成
```

**重要**: このフェーズはエンティティ定義後、画面設計前に実行する。
エンティティを使用してAPIを設計し、画面はAPIを使用して設計する。

## RESTful設計原則

### URL設計

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
| JSONフィールド | camelCase |

## 認証・認可

| 方式 | 用途 |
|------|------|
| Bearer Token (JWT) | 一般的なAPI認証 |
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

## SendMessage 完了報告

タスク完了時に以下の YAML 形式で Lead に SendMessage を送信する:

```yaml
status: ok | needs_input
severity: null
artifacts:
  - docs/05_api_design/api_design.md
  - docs/05_api_design/integration.md
contract_outputs:
  - key: decisions.api_resources
    value:
      - id: API-001
        path: /users
        methods: [GET, POST]
        entities: [ENT-User]
      # 全 API を列挙
  - key: traceability.fr_to_api
    value:
      FR-001: [API-001, API-002]
  - key: traceability.api_to_ent
    value:
      API-001: [ENT-User]
open_questions: []
blockers: []
```

**注意**: project-context.yaml には直接書き込まない（Aggregator の責務）。

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| user-stories 不在 | web-requirements の実行を促す |
| エンティティ不在 | Wave A（database）の実行を促す |
| 未定義エンティティ参照 | P1 として記録、Wave A へ差し戻し提案 |
