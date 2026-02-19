# Phase: Review

設計書レビューフェーズ。
全フェーズの成果物に対して 5 段階チェック（構造・整合性・完全性・ファイル完全性・運用準備）を実施し、
P0/P1/P2 重大度で問題を分類して Gate 判定を行う。

## Contract (YAML)

```yaml
phase_id: "8"
required_artifacts:
  - docs/requirements/user-stories.md
  - docs/requirements/context_unified.md
  - docs/03_architecture/architecture.md
  - docs/04_data_structure/data_structure.md
  - docs/05_api_design/api_design.md
  - docs/06_screen_design/screen_list.md
  - docs/07_implementation/coding_standards.md
  - docs/project-context.yaml             # 任意（無い場合トレーサビリティはスキップ）

outputs:
  - path: docs/08_review/consistency_check.md
    required: true
  - path: docs/08_review/project_completion.md
    required: true

contract_outputs:
  - key: gate.overall
    type: string
    enum: [PASS, ROLLBACK_P1, ROLLBACK_P0]
    description: "Gate 判定結果"
  - key: gate.p0_count
    type: integer
    description: "P0 指摘件数"
  - key: gate.p1_count
    type: integer
    description: "P1 指摘件数"
  - key: gate.p2_count
    type: integer
    description: "P2 指摘件数"
  - key: gate.rollback_targets
    type: array
    description: "差し戻し先フェーズと理由のリスト"
  - key: gate.p2_items
    type: array
    description: "P2 指摘の要対応リスト"

quality_gates:
  - "全フェーズの必須出力ファイルが存在すること（core/output-structure.md 参照）"
  - "トレーサビリティルール（core/traceability.md）に違反がないこと"
  - "レビュー基準（core/review-criteria.md）の 5 段階チェックを全て完了していること"
```

## 入力要件

| 入力 | 必須 | 説明 |
|------|------|------|
| docs/ 配下の設計書（全フェーズ成果物） | ○ | レビュー対象 |
| docs/project-context.yaml | △ | ID・トレーサビリティ情報。無い場合はファイル単体チェック |

**注意**: レビューフェーズは全フェーズの最終工程。全成果物が揃った状態で実行する。

## 出力ファイル

| ファイル | 説明 |
|---------|------|
| docs/08_review/consistency_check.md | 整合性チェック結果（全レベルの指摘一覧） |
| docs/08_review/project_completion.md | 完了サマリー（Gate 判定結果、要対応リスト） |

### consistency_check.md 必須セクション

1. チェック概要（対象ファイル一覧、チェック実施日）
2. Level 1 結果（構造チェック）
3. Level 2 結果（整合性チェック）
4. Level 3 結果（完全性チェック）
5. Level 4 結果（出力ファイル完全性）
6. Level 5 結果（運用準備チェック）
7. 指摘一覧（重大度別テーブル）

### project_completion.md 必須セクション

1. プロジェクト概要
2. Gate 判定結果（overall, P0/P1/P2 件数）
3. 差し戻し対象（ROLLBACK 時のみ）
4. P2 要対応リスト
5. 完了サマリー

## ワークフロー

```
1. docs/ 配下の全設計書を読み込み
2. Level 1: 構造チェック
3. Level 2: 整合性チェック
4. Level 3: 完全性チェック
5. Level 4: 出力ファイル完全性チェック（core/output-structure.md 参照）
6. Level 5: 運用準備チェック
7. 発見した問題を P0/P1/P2 に分類
8. consistency_check.md を生成
9. Gate 判定を実施
10. project_completion.md を生成
11. Gate 結果を出力
```

**各レベルの詳細チェック項目、Gate 判定基準、差し戻しロジック、修正サイクルは `core/review-criteria.md` を参照。**

## レビューレベル概要

5 段階のレビューレベルで検証を行う。各レベルの詳細なチェック項目は `core/review-criteria.md` に定義。

| レベル | 名称 | 概要 |
|--------|------|------|
| Level 1 | 構造チェック | YAML フロントマター、必須セクション、見出し階層、テーブル形式 |
| Level 2 | 整合性チェック | ID 形式準拠、重複/孤児 ID、参照先存在、用語統一、技術スタック整合性 |
| Level 3 | 完全性チェック | プレースホルダー残存、必須項目記入、詳細仕様、受入基準、画面詳細ファイル完全性 |
| Level 4 | 出力ファイル完全性 | 全フェーズの必須ファイル存在確認（`core/output-structure.md` 参照） |
| Level 5 | 運用準備チェック | IPA 準拠の運用準備検証（SLI/SLO、テスト基準、NFR 測定等） |

## トレーサビリティ検証

トレーサビリティのルールは `core/traceability.md` に定義。以下を検証する:

- 全 FR に対応する SC が存在
- 画面操作に対応する API が存在
- API レスポンスの ENT が定義済
- 全 FR/NFR にテストケースがマッピング済

## 画面詳細ファイル完全性

| チェック項目 | 説明 |
|-------------|------|
| 全 SC-ID に対応するファイル存在 | screen_list.md 内の全 SC-ID に screen_detail_SC-XXX.md が存在 |
| ファイル命名規則準拠 | `screen_detail_SC-XXX.md` 形式 |
| 必須セクション存在 | 基本情報、画面レイアウト、コンポーネント構成、状態管理、ユーザー操作、API 連携 |

検証手順:
```
1. screen_list.md から全 SC-ID を抽出
2. details/ ディレクトリ内のファイルを列挙
3. 不足ファイルを P1 として報告
```

## 条件付きチェック

project-context.yaml の `project.profile` を参照し、生成条件に合致するファイルのみチェック対象とする。

- `sla_tier != basic` の場合: backup_restore_dr.md を必須として検証
- `has_migration = true` の場合: migration_plan.md を必須として検証

**profile 未設定時のデフォルト動作**: `sla_tier: basic`, `has_migration: false` として扱う。profile 未設定自体を P2 として記録。

## 修正サイクル

```
レビュー結果: 問題あり
    |
重大度を判定（P0/P1/P2）
    |
P0: 要件定義フェーズへ差し戻し
P1: 該当フェーズへ差し戻し
P2: 要対応リストに記録、通過
    |
差し戻し先で修正
    |
再レビュー（最大3回）
    |
3回超過: ユーザー介入要請
```

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| 設計書不在 | 存在するファイルのみレビュー、欠落を P1 として報告 |
| project-context.yaml 不在 | ファイル単体でチェック、トレーサビリティはスキップ |
| 修正サイクル超過（3回） | 現状で完了、残課題を project_completion.md に記録しユーザー介入を要請 |
| profile 未設定 | デフォルト値で動作、P2 として記録 |
