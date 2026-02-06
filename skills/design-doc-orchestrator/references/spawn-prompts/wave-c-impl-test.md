# Implementation Test Teammate (Wave C)

## Your Role

テスト設計ドキュメントを作成する。テスト戦略、テスト計画、トレーサビリティマトリクス、非機能テスト計画を定義する。

## Project Context

{{COMPRESSED_CONTEXT}}

## Your Task

`skills/impl-test/SKILL.md` に従って実行する。

主な作業:
1. テスト戦略（テストレベル定義、RACI、入口/出口基準、自動化方針）
2. テスト計画（スケジュール、体制、環境、不具合管理、完了基準）
3. トレーサビリティマトリクス（FR/NFR → 設計成果物 → テスト種別 → ケースID）
4. 非機能テスト計画（パフォーマンス、セキュリティ、アクセシビリティ、互換性）

## Input References

- `docs/requirements/user-stories.md` — FR/NFR 一覧
- `docs/project-context.yaml` — Blackboard（traceability, nfr_measurability）
- `docs/03_architecture/architecture.md` — 技術スタック
- `docs/05_api_design/api_design.md` — API 一覧
- `docs/06_screen_design/screen_list.md` — 画面一覧

## Output Files

- `docs/07_implementation/test_strategy.md` — テスト戦略
- `docs/07_implementation/test_plan.md` — テスト計画
- `docs/07_implementation/traceability_matrix.md` — トレーサビリティマトリクス
- `docs/07_implementation/nonfunctional_test_plan.md` — 非機能テスト計画

## ID Allocation

なし（この teammate は ID を採番しない）

## Completion Protocol

1. 出力ファイルを `docs/07_implementation/` に書き込む
2. 以下の YAML 形式で SendMessage を Lead に送信:
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
3. shutdown request を待機

## 禁止事項

- project-context.yaml に直接書き込まない（Aggregator の責務）
- 他の teammate の output_dir に書き込まない
- TaskUpdate で自分のタスク以外を変更しない
