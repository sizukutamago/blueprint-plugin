# 出力ディレクトリ構造

## docs/ 配下の標準構造

```
docs/
├── project-context.yaml           # Blackboard（共有状態管理）
├── requirements/                   # Phase 1-2: 要件定義
│   ├── user-stories.md            #   Gherkin 形式ユーザーストーリー
│   ├── context_unified.md         #   プロジェクトコンテキスト
│   └── story_map.md               #   Epic/Feature/Story 階層
├── 03_architecture/                # Phase 3a/3b: アーキテクチャ設計
│   ├── architecture.md            #   (3a) 技術スタック、パターン、レイヤー構成
│   ├── adr.md                     #   (3a) Architecture Decision Records
│   ├── security.md                #   (3b) セキュリティアーキテクチャ
│   ├── infrastructure.md          #   (3b) インフラ設計
│   └── cache_strategy.md          #   (3b) キャッシュ戦略
├── 04_data_structure/              # Phase 4: データ構造定義
│   └── data_structure.md          #   エンティティ、関係、物理設計
├── 05_api_design/                  # Phase 5: API 仕様
│   ├── api_design.md              #   RESTful API 設計
│   └── integration.md             #   外部システム連携
├── 06_screen_design/               # Phase 6a/6b: 画面設計
│   ├── screen_list.md             #   (6a) 画面一覧
│   ├── screen_transition.md       #   (6a) 画面遷移図
│   ├── component_catalog.md       #   (6b) コンポーネントカタログ
│   ├── error_patterns.md          #   (6b) エラーパターン
│   ├── ui_testing_strategy.md     #   (6b) UI テスト戦略
│   └── details/                   #   (6b) 画面詳細
│       └── screen_detail_SC-XXX.md #   各画面の詳細仕様
├── 07_implementation/              # Phase 7a/7b/7c: 実装準備
│   ├── coding_standards.md        #   (7a) コーディング規約
│   ├── environment.md             #   (7a) 開発環境構築
│   ├── test_strategy.md           #   (7b) テスト戦略
│   ├── test_plan.md               #   (7b) テスト計画
│   ├── traceability_matrix.md     #   (7b) トレーサビリティマトリクス
│   ├── nonfunctional_test_plan.md #   (7b) 非機能テスト計画
│   ├── operations.md              #   (7c) 運用手順
│   ├── observability_design.md    #   (7c) 可観測性設計
│   ├── incident_response.md       #   (7c) インシデント対応計画
│   ├── backup_restore_dr.md       #   (7c) [条件付き] sla_tier != basic
│   └── migration_plan.md          #   (7c) [条件付き] has_migration = true
└── 08_review/                      # Phase 8: レビュー
    ├── consistency_check.md        #   整合性チェック結果
    └── project_completion.md       #   完了サマリー
```

## 必須ファイル一覧

| フェーズ | ファイル | 必須 | 条件 |
|---------|---------|------|------|
| Phase 1-2 | requirements/user-stories.md | ○ | - |
| Phase 1-2 | requirements/context_unified.md | ○ | - |
| Phase 1-2 | requirements/story_map.md | ○ | - |
| Phase 3a | 03_architecture/architecture.md | ○ | - |
| Phase 3a | 03_architecture/adr.md | ○ | - |
| Phase 3b | 03_architecture/security.md | ○ | - |
| Phase 3b | 03_architecture/infrastructure.md | ○ | - |
| Phase 3b | 03_architecture/cache_strategy.md | ○ | - |
| Phase 4 | 04_data_structure/data_structure.md | ○ | - |
| Phase 5 | 05_api_design/api_design.md | ○ | - |
| Phase 5 | 05_api_design/integration.md | ○ | - |
| Phase 6a | 06_screen_design/screen_list.md | ○ | - |
| Phase 6a | 06_screen_design/screen_transition.md | ○ | - |
| Phase 6b | 06_screen_design/component_catalog.md | ○ | - |
| Phase 6b | 06_screen_design/error_patterns.md | ○ | - |
| Phase 6b | 06_screen_design/ui_testing_strategy.md | ○ | - |
| Phase 6b | 06_screen_design/details/screen_detail_SC-XXX.md | ○ | 全 SC-ID 分 |
| Phase 7a | 07_implementation/coding_standards.md | ○ | - |
| Phase 7a | 07_implementation/environment.md | ○ | - |
| Phase 7b | 07_implementation/test_strategy.md | ○ | - |
| Phase 7b | 07_implementation/test_plan.md | ○ | - |
| Phase 7b | 07_implementation/traceability_matrix.md | ○ | - |
| Phase 7b | 07_implementation/nonfunctional_test_plan.md | ○ | - |
| Phase 7c | 07_implementation/operations.md | ○ | - |
| Phase 7c | 07_implementation/observability_design.md | ○ | - |
| Phase 7c | 07_implementation/incident_response.md | ○ | - |
| Phase 7c | 07_implementation/backup_restore_dr.md | △ | sla_tier != basic |
| Phase 7c | 07_implementation/migration_plan.md | △ | has_migration = true |
| Phase 8 | 08_review/consistency_check.md | ○ | - |
| Phase 8 | 08_review/project_completion.md | ○ | - |
