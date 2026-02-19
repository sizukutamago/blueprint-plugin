---
name: database
description: This skill should be used when the user asks to "design data model", "create entity definitions", "define TypeScript types", "design database schema", "create data structure", or "model entities". Defines data structures and entity models with TypeScript type definitions for Wave A parallel execution.
version: 2.0.0
model: sonnet
core_ref: core/phases/database.md
---

# Database Skill (Claude Code)

Wave A で実行されるデータ構造・エンティティ定義スキル。

## 仕様参照

このフェーズの仕様は `core/phases/database.md` に定義されている。
入力要件、出力ファイル、必須セクション、品質基準、ワークフローは全て core を参照すること。

## Claude Code 固有: 実行コンテキスト

- **実行タイミング**: Wave A（architecture-skeleton, design-inventory と並列）
- **前提スキル**: web-requirements
- **並列スキル**: architecture-skeleton, design-inventory
- **後続スキル**: api（Wave B）, wave-aggregator

## Claude Code 固有: 技術スタック受領

ユーザー承認済み技術スタックはスポーンプロンプト経由で受領する。
- `{{USER_APPROVED_TECH_STACK}}` プレースホルダーが置換済み
- DB/ORM の指定がある場合はそれに従って物理設計を実施

## Claude Code 固有: SendMessage 完了報告

タスク完了時に以下の YAML 形式で Lead に SendMessage を送信する:

```yaml
status: ok | needs_input
severity: null
artifacts:
  - docs/04_data_structure/data_structure.md
contract_outputs:
  - key: decisions.entities
    value:
      - id: ENT-User
        name: User
        attributes: [id, email, name, role, ...]
        physical:
          table_name: users
          indexes: [idx_users_email]
          estimated_rows: 10000
          data_classification: [PII, Internal]
      # 全エンティティを列挙（physical 含む）
  - key: traceability.fr_to_ent
    value:
      FR-001: [ENT-User]
      # FR → ENT マッピング
open_questions: []
blockers: []
```

**注意**: project-context.yaml には直接書き込まない（Aggregator の責務）。
