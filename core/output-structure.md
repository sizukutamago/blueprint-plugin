# v5 出力構造

v5 の `/generate-docs` で生成する設計書の出力先構造。
v4 の `core/output-structure.md` と互換性を持つ。

## docs/ 配下の構造

```
docs/
├── 03_architecture/                # アーキテクチャ設計
│   ├── architecture.md            #   技術スタック、パターン、レイヤー構成
│   ├── adr.md                     #   Architecture Decision Records
│   ├── security.md                #   セキュリティアーキテクチャ
│   ├── infrastructure.md          #   インフラ設計
│   └── cache_strategy.md          #   キャッシュ戦略
├── 04_data_structure/              # データ構造
│   └── data_structure.md          #   エンティティ、関係、物理設計
├── 05_api_design/                  # API 仕様
│   ├── api_design.md              #   API エンドポイント設計
│   └── integration.md             #   外部システム連携
├── 06_screen_design/               # 画面設計（フロントエンドがある場合）
│   ├── screen_list.md             #   画面一覧
│   ├── screen_transition.md       #   画面遷移図
│   ├── component_catalog.md       #   コンポーネントカタログ
│   ├── error_patterns.md          #   エラーパターン
│   ├── ui_testing_strategy.md     #   UI テスト戦略
│   └── details/                   #   画面詳細
│       └── screen_detail_SC-XXX.md
├── 07_implementation/              # 実装準備
│   ├── coding_standards.md        #   コーディング規約
│   ├── environment.md             #   開発環境構築
│   ├── test_strategy.md           #   テスト戦略
│   ├── test_plan.md               #   テスト計画
│   ├── traceability_matrix.md     #   トレーサビリティマトリクス
│   ├── nonfunctional_test_plan.md #   非機能テスト計画
│   ├── operations.md              #   運用手順
│   ├── observability_design.md    #   可観測性設計
│   ├── incident_response.md       #   インシデント対応計画
│   ├── backup_restore_dr.md       #   [条件付き] DR 計画
│   └── migration_plan.md          #   [条件付き] マイグレーション計画
└── 08_review/                      # レビュー
    ├── consistency_check.md        #   整合性チェック結果
    └── project_completion.md       #   完了サマリー + 確信度レポート
```

## v4 との差分

| 項目 | v4 | v5 |
|------|-----|-----|
| requirements/ | 必須（Phase 1-2 出力） | なし（Contract が代替） |
| project-context.yaml | 必須（Blackboard） | なし（.blueprint/ が代替） |
| 生成方向 | 要件→設計書 (top-down) | コード→設計書 (bottom-up) |
| 06_screen_design/ | 必須 | 条件付き（フロントエンドなしならスキップ） |
| 確信度 | なし | あり（high/medium/low） |

## 生成条件

| ディレクトリ | 必須 | スキップ条件 |
|------------|------|------------|
| 03_architecture/ | ○ | — |
| 04_data_structure/ | ○ | DB なしのプロジェクトでも最低限のデータモデル記述 |
| 05_api_design/ | ○ | API なしの場合は integration.md のみ |
| 06_screen_design/ | △ | フロントエンドなしならスキップ |
| 07_implementation/ | ○ | — |
| 08_review/ | ○ | — |

## 確信度マーカー

各セクションに確信度を含める:

```markdown
## 技術スタック <!-- confidence: high -->

| カテゴリ | 技術 | バージョン |
|---------|------|-----------|
| Runtime | Node.js | 20.x |
| Framework | Hono | 4.x |
...

## キャッシュ戦略 <!-- confidence: low -->
<!-- TODO: Redis 設定が見つからない。キャッシュ実装の有無を確認してください -->
```
