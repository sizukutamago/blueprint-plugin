---
name: implementation
description: This skill should be used when the user asks to "create coding standards", "setup development environment", "define deployment process", or "document implementation guidelines". Creates implementation preparation documents.
version: 2.0.0
core_ref: core/phases/impl-standards.md
---

# Implementation Standards Skill (Claude Code)

コーディング規約と開発環境設定を作成するスキル。

## 仕様参照

このフェーズの仕様は `core/phases/impl-standards.md` に定義されている。
入力要件、出力ファイル、必須セクション、品質基準、ワークフローは全て core を参照すること。

## Claude Code 固有: 実行コンテキスト

- **実行タイミング**: Wave C（impl-test, impl-ops と並列）
- **前提スキル**: architecture, design-detail
- **並列スキル**: impl-test, impl-ops（Wave C）
- **後続スキル**: review

## Claude Code 固有: SendMessage 完了報告

タスク完了時に以下の YAML 形式で Lead に SendMessage を送信する:

```yaml
status: ok
severity: null
artifacts:
  - docs/07_implementation/coding_standards.md
  - docs/07_implementation/environment.md
contract_outputs: []
open_questions: []
blockers: []
```

**注意**: project-context.yaml には直接書き込まない（Aggregator の責務）。
