# Wave 構成と依存関係定義

## 概要

設計ドキュメントワークフローは 13 タスクの DAG（有向非巡回グラフ）で構成される。
Wave 内のタスクは並列実行可能、Wave 間は順次実行。

## DAG 定義

```
task-1:  web-requirements          depends_on: []           wave: -
task-2:  architecture-skeleton     depends_on: [1]          wave: A
task-3:  database                  depends_on: [1]          wave: A
task-4:  design-inventory          depends_on: [1]          wave: A
task-5:  wave-aggregator-a         depends_on: [2,3,4]      wave: A (統合)
task-6:  api                       depends_on: [5]          wave: B
task-7:  architecture-detail       depends_on: [5]          wave: B
task-8:  wave-aggregator-b         depends_on: [6,7]        wave: B (統合)
task-9:  design-detail             depends_on: [8]          wave: post-B
task-10: impl-standards            depends_on: [9]          wave: C
task-11: impl-test                 depends_on: [9]          wave: C
task-12: impl-ops                  depends_on: [9]          wave: C
task-13: review                    depends_on: [10,11,12]   wave: Seq
```

## Wave 構成図

```
                    ┌─ arch-skeleton ─┐
web-requirements ─→ ├─ database      ─┤→ aggregator-A ─→ ┌─ api          ─┐→ aggregator-B ─→ design-detail
                    └─ design-inv    ─┘                   └─ arch-detail  ─┘
                                                                                    │
                                                                          ┌─ impl-standards ─┐
                                                                          ├─ impl-test      ─┤→ review
                                                                          └─ impl-ops       ─┘
```

## Wave ごとの並列度

| Wave | タスク | 並列度 | Aggregator 必要 |
|------|--------|--------|----------------|
| A | arch-skeleton, database, design-inventory | 3 | あり |
| B | api, architecture-detail | 2 | あり |
| post-B | design-detail | 1 | なし |
| C | impl-standards, impl-test, impl-ops | 3 | なし |
| Seq | review | 1 | なし |

## Aggregator の役割

Wave A/B 完了後、各フェーズの出力を統合して Blackboard（project-context.yaml）を更新する。
Wave C と Seq では Aggregator は不要（先行成果物を直接参照）。

### Aggregator の処理（Two-step Reduce）

1. **Collect**: 各フェーズの Blackboard 出力をマージ
2. **Normalize**: キー名の正規化とコンフリクト解消
   - `decisions.*` → `blackboard.decisions.*`
   - `traceability.*` → トップレベルに配置
   - `id_registry.*` → トップレベルに配置

## コンテキスト圧縮戦略

各 Wave 開始時に、先行成果物をコンテキストとして渡す。
トークン効率のため、Wave ごとに異なる圧縮戦略を使用する。

| Wave | 入力コンテキスト | 圧縮手法 | 目標サイズ |
|------|----------------|---------|-----------|
| A | docs/requirements/ + approved_tech_stack | Chain of Density | ~10k tokens |
| B | docs/requirements/ + project-context.yaml | Entity Signature Only | ~15k tokens |
| post-B | project-context.yaml + 出力ファイル参照 | Decision Summary | ~10k tokens |
| C | project-context.yaml + 先行成果物 | Decision Summary | ~10k tokens |
| Seq | project-context.yaml 全体 | Decision Summary | ~10k tokens |

## 条件付きタスク

`project.profile` に基づき、一部タスクの出力が変わる:

| 条件 | 影響するタスク | 影響 |
|------|-------------|------|
| `sla_tier = basic` | impl-ops | backup_restore_dr.md をスキップ |
| `has_migration = false` | impl-ops | migration_plan.md をスキップ |
| `scale = small` | impl-test | NFR テスト計画を簡略化 |
