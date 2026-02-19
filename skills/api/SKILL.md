---
name: api
description: This skill should be used when the user asks to "design API", "create REST endpoints", "document API specifications", "define API contracts", "plan external integrations", or "create OpenAPI spec". Designs RESTful APIs and external system integration specifications for Wave B parallel execution.
version: 2.0.0
model: sonnet
core_ref: core/phases/api.md
---

# API Skill (Claude Code)

Wave B で実行される API 設計スキル。

## 仕様参照

このフェーズの仕様は `core/phases/api.md` に定義されている。
入力要件、出力ファイル、必須セクション、品質基準、ワークフローは全て core を参照すること。

## Claude Code 固有: 実行コンテキスト

- **実行タイミング**: Wave B（architecture-detail と並列、Wave A 完了後）
- **前提スキル**: web-requirements, database（Wave A）
- **並列スキル**: architecture-detail（Wave B）
- **後続スキル**: design-detail（post-B）, wave-aggregator

## Claude Code 固有: SendMessage 完了報告

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
