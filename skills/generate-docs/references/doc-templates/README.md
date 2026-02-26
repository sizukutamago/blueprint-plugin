# Doc Templates

v4 の各 phase 出力フォーマットを参照して設計書を生成する。
テンプレートファイルは v4 の `core/phases/*.md` に定義されたフォーマットをそのまま使用するため、
ここに個別テンプレートは配置しない。

## 参照先

| 設計書 | v4 仕様参照先 |
|--------|-------------|
| architecture.md | `core/phases/architecture-skeleton.md` |
| security.md, infrastructure.md, cache_strategy.md | `core/phases/architecture-detail.md` |
| data_structure.md | `core/phases/database.md` |
| api_design.md, integration.md | `core/phases/api.md` |
| screen_list.md, screen_transition.md | `core/phases/design-inventory.md` |
| component_catalog.md, error_patterns.md, screen_detail | `core/phases/design-detail.md` |
| coding_standards.md, environment.md | `core/phases/impl-standards.md` |
| test_strategy.md, test_plan.md, traceability_matrix.md | `core/phases/impl-test.md` |
| operations.md, observability_design.md, incident_response.md | `core/phases/impl-ops.md` |
| consistency_check.md, project_completion.md | `core/phases/review.md` |
