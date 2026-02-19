---
name: review
description: This skill should be used when the user asks to "review design documents", "check document consistency", "validate traceability", "generate completion summary", "audit design specifications", or "check ID consistency". Performs consistency checks and reviews on design documentation with P0/P1/P2 severity-based Gate judgment.
version: 4.0.0
core_ref: core/phases/review.md
---

# Review Skill (Claude Code Wrapper)

仕様の本体は `core/phases/review.md` を参照。
レビュー基準・Gate 判定・差し戻しロジックの詳細は `core/review-criteria.md` を参照。

このファイルは Claude Code agent-teams 固有の実行手順のみ定義する。

## 参照テンプレート

| ファイル | 説明 |
|---------|------|
| {baseDir}/references/consistency_check.md | 整合性チェック結果テンプレート |
| {baseDir}/references/project_completion.md | 完了サマリーテンプレート |
| {baseDir}/references/review_template.md | 個別レビュー時の書式参考用（成果物としては生成しない） |

## SendMessage 完了報告（Gate 結果）

Gate 判定結果を以下の YAML 形式で Lead に SendMessage を送信する:

```yaml
status: ok | conflict
severity: null | P0 | P1
artifacts:
  - docs/08_review/consistency_check.md
  - docs/08_review/project_completion.md
gate:
  overall: PASS | ROLLBACK_P1 | ROLLBACK_P0
  p0_count: 0
  p1_count: 0
  p2_count: 0
  rollback_targets:
    - phase: database
      reason: "API-003 が参照する ENT-Order が未定義"
  p2_items:
    - "詳細仕様に「など」が残存"
contract_outputs: []
open_questions: []
blockers:
  - "P0: FR-003 に対応する API が未定義"
```

**注意**: project-context.yaml には直接書き込まない（Aggregator の責務）。
