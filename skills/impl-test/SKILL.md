---
name: impl-test
description: This skill should be used when the user asks to "create test strategy", "design test plan", "build traceability matrix", "plan non-functional testing", or "define test completion criteria". Creates test design documents aligned with IPA/IEEE 829/JSTQB standards.
version: 1.0.0
---

# Test Design Skill

テスト設計ドキュメントを作成するスキル。
IPA共通フレーム・IEEE 829・JSTQBに準拠したテスト戦略・計画・トレーサビリティを設計する。

**実行タイミング**: Wave C（impl-standards, impl-ops と並列）

## 前提条件

| 条件 | 必須 | 説明 |
|------|------|------|
| docs/requirements/user-stories.md | ○ | FR/NFR一覧 |
| docs/03_architecture/architecture.md | ○ | 技術スタック情報 |
| docs/04_data_structure/data_structure.md | ○ | エンティティ定義 |
| docs/05_api_design/api_design.md | ○ | API仕様 |
| docs/06_screen_design/screen_list.md | ○ | 画面一覧 |
| docs/project-context.yaml | ○ | Blackboard（トレーサビリティ・NFR測定可能性） |

## 出力ファイル

| ファイル | テンプレート | 説明 |
|---------|-------------|------|
| docs/07_implementation/test_strategy.md | {baseDir}/references/test_strategy.md | テスト戦略 |
| docs/07_implementation/test_plan.md | {baseDir}/references/test_plan.md | テスト計画 |
| docs/07_implementation/traceability_matrix.md | {baseDir}/references/traceability_matrix.md | トレーサビリティマトリクス |
| docs/07_implementation/nonfunctional_test_plan.md | {baseDir}/references/nonfunctional_test_plan.md | 非機能テスト計画 |

## 依存関係

| 種別 | 対象 |
|------|------|
| 前提スキル | architecture, database, api, design-detail |
| 並列スキル | impl-standards, impl-ops（Wave C） |
| 後続スキル | review |

## ワークフロー

```
1. 全設計書（architecture, database, api, design）を読み込み
2. project-context.yaml から NFR 測定可能性データを取得
3. テスト戦略を策定（レベル別定義、リスクベース優先順位）
4. テスト計画を策定（スケジュール、体制、環境、完了基準）
5. トレーサビリティマトリクスを生成（FR/NFR → 設計 → テスト）
6. 非機能テスト計画を策定（NFR-ID毎の測定方法・合否基準）
```

## テスト戦略の要素

### テストレベル

| レベル | 目的 | ツール | カバレッジ |
|--------|------|--------|-----------|
| 単体テスト | ロジック検証 | Jest/Vitest | 80% |
| 結合テスト | API/DB契約検証 | Supertest | 主要パス |
| E2Eテスト | ユーザーフロー検証 | Playwright | 主要シナリオ |
| 受入テスト | Gherkin検証 | - | 全FR |

### リスクベース優先順位

| リスクレベル | 定義 | テスト深度 |
|------------|------|-----------|
| High | 決済・認証・データ整合性 | 全パス+境界値+異常系 |
| Medium | CRUD・検索・一覧 | 主要パス+代表的異常系 |
| Low | 静的表示・設定 | 正常系のみ |

## SendMessage 完了報告

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

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| NFR測定可能性データ不在 | WARNING: 汎用的な測定基準で代替、レビューで指摘 |
| 設計書の一部が不在 | 利用可能な設計書のみでマトリクス生成、不在分は「未検証」とマーク |
