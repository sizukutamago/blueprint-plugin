---
name: design-inventory
description: This skill should be used when the user asks to "list screens", "design screen flow", "create screen inventory", "plan navigation", or "map user journeys". Creates screen inventory and transition diagrams for Wave A parallel execution.
version: 2.0.0
model: sonnet
core_ref: core/phases/design-inventory.md
---

# Design Inventory Skill (Claude Code)

Wave A で実行される画面棚卸しスキル。

## 仕様参照

このフェーズの仕様は `core/phases/design-inventory.md` に定義されている。
入力要件、出力ファイル、必須セクション、品質基準、ワークフローは全て core を参照すること。

## Claude Code 固有: 実行コンテキスト

- **実行タイミング**: Wave A（architecture-skeleton, database と並列）
- **前提スキル**: web-requirements
- **並列スキル**: architecture-skeleton, database
- **後続スキル**: design-detail（Post-B）

## Claude Code 固有: SendMessage 完了報告

タスク完了時に以下の YAML 形式で Lead に SendMessage を送信する:

```yaml
status: ok
severity: null
artifacts:
  - docs/06_screen_design/screen_list.md
  - docs/06_screen_design/screen_transition.md
contract_outputs:
  - key: decisions.screens
    value:
      - id: SC-001
        name: ログイン画面
        category: Auth
        url: /login
        fr_refs: [FR-001]
      # 全画面を列挙
  - key: traceability.fr_to_sc
    value:
      FR-001: [SC-001, SC-002]
open_questions:
  - "画面詳細は Post-B で design-detail が実施"
blockers: []
```

**注意**: project-context.yaml には直接書き込まない（Aggregator の責務）。
