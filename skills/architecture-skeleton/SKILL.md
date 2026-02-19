---
name: architecture-skeleton
description: This skill should be used when the user asks to "define architecture skeleton", "select technology stack", "create ADR", "define system boundaries", "set NFR policies", or "plan high-level architecture". Designs high-level system architecture, technology selection, and NFR policies for Wave A parallel execution.
version: 2.0.0
model: opus
core_ref: core/phases/architecture-skeleton.md
---

# Architecture Skeleton Skill (Claude Code)

Wave A で実行される高レベルアーキテクチャ設計スキル。

## 仕様参照

このフェーズの仕様は `core/phases/architecture-skeleton.md` に定義されている。
入力要件、出力ファイル、必須セクション、品質基準、ワークフローは全て core を参照すること。

## Claude Code 固有: 実行コンテキスト

- **実行タイミング**: Wave A（database, design-inventory と並列）
- **前提スキル**: web-requirements
- **並列スキル**: database, design-inventory
- **後続スキル**: architecture-detail, api（Wave B）

## Claude Code 固有: 技術スタック受領

ユーザー承認済み技術スタックはスポーンプロンプト経由で受領する。
- `{{USER_APPROVED_TECH_STACK}}` プレースホルダーが置換済み
- `mode: auto` の場合は自律選定
- `mode: specified` の場合はユーザー指定を必須制約として採用

## Claude Code 固有: SendMessage 完了報告

タスク完了時に以下の YAML 形式で Lead に SendMessage を送信する:

```yaml
status: ok | needs_input
severity: null
artifacts:
  - docs/03_architecture/architecture.md
  - docs/03_architecture/adr.md
contract_outputs:
  - key: decisions.architecture.tech_stack
    value: [選定した技術スタック]
  - key: decisions.architecture.user_constraints
    value: {ユーザー承認済み技術スタック（mode, 各カテゴリ）をそのまま転記}
  - key: decisions.architecture.boundaries
    value: [定義したシステム境界]
  - key: decisions.architecture.nfr_policies
    value: {NFR ポリシー}
  - key: decisions.nfr_measurability
    value:
      NFR-PERF-001:
        target: "API応答時間 p95 < 200ms"
        measurement: "k6 負荷テスト"
        pass_criteria: "p95 < 200ms かつ p99 < 500ms"
open_questions:
  - "キャッシュ戦略は Wave B（architecture-detail）で決定"
blockers: []
```

**注意**: project-context.yaml には直接書き込まない（Aggregator の責務）。
