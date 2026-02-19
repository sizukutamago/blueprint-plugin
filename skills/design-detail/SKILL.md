---
name: design-detail
description: This skill should be used when the user asks to "design screen details", "create wireframes", "define component catalog", "specify error patterns", "plan UI testing", or "document screen specifications". Designs detailed screen specifications, components, and UI patterns after Wave B completion.
version: 2.0.0
model: sonnet
core_ref: core/phases/design-detail.md
---

# Design Detail Skill (Claude Code)

Wave B 後に実行される画面詳細設計スキル。

## 仕様参照

このフェーズの仕様は `core/phases/design-detail.md` に定義されている。
入力要件、出力ファイル、必須セクション、品質基準、ワークフローは全て core を参照すること。

## Claude Code 固有: 実行コンテキスト

- **実行タイミング**: Post-B（Wave B 完了後）
- **前提スキル**: design-inventory（Wave A）, api（Wave B）, architecture-detail（Wave B）
- **後続スキル**: implementation, impl-test, impl-ops（Wave C）, review

## Claude Code 固有: SendMessage 完了報告

タスク完了時に以下の YAML 形式で Lead に SendMessage を送信する:

```yaml
status: ok
severity: null
artifacts:
  - docs/06_screen_design/component_catalog.md
  - docs/06_screen_design/error_patterns.md
  - docs/06_screen_design/ui_testing_strategy.md
  - docs/06_screen_design/details/screen_detail_SC-001.md
  # 全 SC-ID 分を列挙
contract_outputs:
  - key: traceability.api_to_sc
    value:
      API-001: [SC-002, SC-003]
  - key: decisions.screens
    value: [画面詳細情報を追加]
open_questions: []
blockers: []
```

**注意**: project-context.yaml には直接書き込まない（Aggregator の責務）。
