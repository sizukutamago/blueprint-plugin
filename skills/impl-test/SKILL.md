---
name: impl-test
description: This skill should be used when the user asks to "create test strategy", "design test plan", "build traceability matrix", "plan non-functional testing", or "define test completion criteria". Creates test design documents aligned with IPA/IEEE 829/JSTQB standards.
version: 2.0.0
core_ref: core/phases/impl-test.md
---

# Test Design Skill (Claude Code)

テスト設計ドキュメントを作成するスキル。

## 仕様参照

このフェーズの仕様は `core/phases/impl-test.md` に定義されている。
入力要件、出力ファイル、必須セクション、品質基準、ワークフローは全て core を参照すること。

## Claude Code 固有: 実行コンテキスト

- **実行タイミング**: Wave C（impl-standards, impl-ops と並列）
- **前提スキル**: architecture-skeleton, database, api, design-detail
- **並列スキル**: impl-standards, impl-ops（Wave C）
- **後続スキル**: review

## Claude Code 固有: SendMessage 完了報告

タスク完了時に以下の YAML 形式で Lead に SendMessage を送信する:

```yaml
status: ok
severity: null
artifacts:
  - docs/07_implementation/test_strategy.md
  - docs/07_implementation/test_plan.md
  - docs/07_implementation/traceability_matrix.md
  - docs/07_implementation/nonfunctional_test_plan.md
contract_outputs: []
open_questions: []
blockers: []
```

**注意**: project-context.yaml には直接書き込まない（Aggregator の責務）。
