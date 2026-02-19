---
name: impl-ops
description: This skill should be used when the user asks to "design observability", "create SLI/SLO", "write incident response plan", "design monitoring", "create backup strategy", "plan migration", or "write operations runbook". Creates operations and infrastructure design documents.
version: 2.0.0
core_ref: core/phases/impl-ops.md
---

# Operations Design Skill (Claude Code)

運用設計ドキュメントを作成するスキル。

## 仕様参照

このフェーズの仕様は `core/phases/impl-ops.md` に定義されている。
入力要件、出力ファイル、必須セクション、品質基準、ワークフローは全て core を参照すること。
条件付き生成ルール（sla_tier, has_migration）も core に定義済み。

## Claude Code 固有: 実行コンテキスト

- **実行タイミング**: Wave C（impl-standards, impl-test と並列）
- **前提スキル**: architecture, architecture-detail
- **並列スキル**: impl-standards, impl-test（Wave C）
- **後続スキル**: review

## Claude Code 固有: SendMessage 完了報告

タスク完了時に以下の YAML 形式で Lead に SendMessage を送信する:

```yaml
status: ok
severity: null
artifacts:
  - docs/07_implementation/operations.md
  - docs/07_implementation/observability_design.md
  - docs/07_implementation/incident_response.md
  # 以下は条件付き
  - docs/07_implementation/backup_restore_dr.md
  - docs/07_implementation/migration_plan.md
contract_outputs: []
open_questions: []
blockers: []
```

**注意**: project-context.yaml には直接書き込まない（Aggregator の責務）。
