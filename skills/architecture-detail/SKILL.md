---
name: architecture-detail
description: This skill should be used when the user asks to "design security architecture", "plan infrastructure", "define caching strategy", "detail system configuration", or "finalize architecture". Designs detailed security, infrastructure, and caching strategies after Wave A/B completion.
version: 2.0.0
model: sonnet
core_ref: core/phases/architecture-detail.md
---

# Architecture Detail Skill (Claude Code)

Wave B で実行される詳細アーキテクチャ設計スキル。

## 仕様参照

このフェーズの仕様は `core/phases/architecture-detail.md` に定義されている。
入力要件、出力ファイル、必須セクション、品質基準、ワークフローは全て core を参照すること。

## Claude Code 固有: 実行コンテキスト

- **実行タイミング**: Wave B（api と並列）
- **前提スキル**: architecture-skeleton（Wave A）
- **並列スキル**: api（Wave B）
- **後続スキル**: design-detail, implementation

## Claude Code 固有: SendMessage 完了報告

タスク完了時に以下の YAML 形式で Lead に SendMessage を送信する:

```yaml
status: ok | needs_input
severity: null
artifacts:
  - docs/03_architecture/security.md
  - docs/03_architecture/infrastructure.md
  - docs/03_architecture/cache_strategy.md
contract_outputs:
  - key: decisions.architecture.security
    value: {認証/認可/脆弱性対策/データガバナンス}
  - key: decisions.architecture.cache
    value: {キャッシュ戦略}
  - key: decisions.architecture.infrastructure
    value: {インフラ構成}
open_questions: []
blockers: []
```

**注意**: project-context.yaml には直接書き込まない（Aggregator の責務）。
