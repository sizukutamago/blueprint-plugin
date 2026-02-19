# Phase: Test Design

テスト設計ドキュメントを作成するフェーズ。
IPA 共通フレーム・IEEE 829・JSTQB に準拠したテスト戦略・計画・トレーサビリティを設計する。

## Contract (YAML)

```yaml
phase_id: "7b"
required_artifacts:
  - docs/requirements/user-stories.md
  - docs/03_architecture/architecture.md
  - docs/04_data_structure/data_structure.md
  - docs/05_api_design/api_design.md
  - docs/06_screen_design/screen_list.md
  - docs/project-context.yaml                      # Blackboard（トレーサビリティ・NFR測定可能性）

outputs:
  - path: docs/07_implementation/test_strategy.md
    required: true
  - path: docs/07_implementation/test_plan.md
    required: true
  - path: docs/07_implementation/traceability_matrix.md
    required: true
  - path: docs/07_implementation/nonfunctional_test_plan.md
    required: true

contract_outputs: []

quality_gates:
  - "全 FR-ID がトレーサビリティマトリクスに存在すること"
  - "全 NFR-ID が非機能テスト計画に測定方法と合否基準を持つこと"
  - "テスト戦略のツール選定が architecture.md の技術スタックと整合していること"
```

## 入力要件

| 入力 | 必須 | 説明 |
|------|------|------|
| docs/requirements/user-stories.md | ○ | FR/NFR 一覧 |
| docs/03_architecture/architecture.md | ○ | 技術スタック情報 |
| docs/04_data_structure/data_structure.md | ○ | エンティティ定義 |
| docs/05_api_design/api_design.md | ○ | API 仕様 |
| docs/06_screen_design/screen_list.md | ○ | 画面一覧 |
| docs/project-context.yaml | ○ | Blackboard（トレーサビリティ・NFR 測定可能性） |

## 出力ファイル

| ファイル | テンプレート | 説明 |
|---------|-------------|------|
| docs/07_implementation/test_strategy.md | references/test_strategy.md | テスト戦略 |
| docs/07_implementation/test_plan.md | references/test_plan.md | テスト計画 |
| docs/07_implementation/traceability_matrix.md | references/traceability_matrix.md | トレーサビリティマトリクス |
| docs/07_implementation/nonfunctional_test_plan.md | references/nonfunctional_test_plan.md | 非機能テスト計画 |

## ワークフロー

```
1. 全設計書（architecture, database, api, design）を読み込み
2. Blackboard から NFR 測定可能性データを取得
3. テスト戦略を策定
   - テストレベル別定義（単体/結合/E2E/受入）
   - リスクベース優先順位付け
   - ツール選定（技術スタックに基づく）
4. テスト計画を策定
   - スケジュール
   - 体制
   - テスト環境
   - 完了基準
5. トレーサビリティマトリクスを生成
   - FR/NFR → 設計成果物 → テストケース
6. 非機能テスト計画を策定
   - NFR-ID 毎の測定方法・ツール・合否基準
7. contract_outputs を出力
```

## テスト戦略の要素

### テストレベル

| レベル | 目的 | ツール | カバレッジ |
|--------|------|--------|-----------|
| 単体テスト | ロジック検証 | Jest/Vitest | 80% |
| 結合テスト | API/DB 契約検証 | Supertest | 主要パス |
| E2E テスト | ユーザーフロー検証 | Playwright | 主要シナリオ |
| 受入テスト | Gherkin 検証 | - | 全 FR |

### リスクベース優先順位

| リスクレベル | 定義 | テスト深度 |
|------------|------|-----------|
| High | 決済・認証・データ整合性 | 全パス+境界値+異常系 |
| Medium | CRUD・検索・一覧 | 主要パス+代表的異常系 |
| Low | 静的表示・設定 | 正常系のみ |

### NFR 測定可能性からのデータフロー

```
architecture-skeleton (nfr_measurability)
  → Blackboard に記録
    → impl-test が参照
      → nonfunctional_test_plan.md に展開
        → review で検証
```

各 NFR-ID に対して以下の3要素を非機能テスト計画に反映する:
- **target**: 達成目標（Blackboard から取得）
- **measurement**: 測定方法・ツール（具体的なテスト手順に展開）
- **pass_criteria**: 合否基準（テスト完了判定に使用）

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| NFR 測定可能性データ不在 | WARNING: 汎用的な測定基準で代替、レビューで指摘 |
| 設計書の一部が不在 | 利用可能な設計書のみでマトリクス生成、不在分は「未検証」とマーク |
