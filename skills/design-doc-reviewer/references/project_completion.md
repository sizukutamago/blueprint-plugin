# プロジェクト完了サマリー

---

## プロジェクト情報

| 項目 | 内容 |
|------|------|
| プロジェクト名 | {{PROJECT_NAME}} |
| 確認日 | {{CHECK_DATE}} |
| 確認担当者 | {{CHECKER}} |
| 総合判定 | {{OVERALL_RESULT}} |

総合判定の凡例: ✅ 完了 / ⚠️ 条件付き完了 / ❌ 未完了

---

## 成果物一覧

| # | 成果物 | ステータス | Level1 | Level2 | Level3 | 備考 |
|---|--------|-----------|--------|--------|--------|------|
| 1 | user-stories.md | {{STATUS}} | {{L1}} | {{L2}} | {{L3}} | docs/requirements/ |
| 2 | context_unified.md | {{STATUS}} | {{L1}} | {{L2}} | {{L3}} | docs/requirements/ |
| 3 | story_map.md | {{STATUS}} | {{L1}} | {{L2}} | {{L3}} | docs/requirements/ |
| 4 | architecture.md | {{STATUS}} | {{L1}} | {{L2}} | {{L3}} | 03_architecture/ (Wave A) |
| 5 | adr.md | {{STATUS}} | {{L1}} | {{L2}} | {{L3}} | 03_architecture/ (Wave A) |
| 6 | security.md | {{STATUS}} | {{L1}} | {{L2}} | {{L3}} | 03_architecture/ (Wave B) |
| 7 | infrastructure.md | {{STATUS}} | {{L1}} | {{L2}} | {{L3}} | 03_architecture/ (Wave B) |
| 8 | cache_strategy.md | {{STATUS}} | {{L1}} | {{L2}} | {{L3}} | 03_architecture/ (Wave B) |
| 9 | data_structure.md | {{STATUS}} | {{L1}} | {{L2}} | {{L3}} | 04_data_structure/ (Wave A) |
| 10 | api_design.md | {{STATUS}} | {{L1}} | {{L2}} | {{L3}} | 05_api_design/ (Wave B) |
| 11 | integration.md | {{STATUS}} | {{L1}} | {{L2}} | {{L3}} | 05_api_design/ (Wave B) |
| 12 | screen_list.md | {{STATUS}} | {{L1}} | {{L2}} | {{L3}} | 06_screen_design/ (Wave A) |
| 13 | screen_transition.md | {{STATUS}} | {{L1}} | {{L2}} | {{L3}} | 06_screen_design/ (Wave A) |
| 14 | component_catalog.md | {{STATUS}} | {{L1}} | {{L2}} | {{L3}} | 06_screen_design/ (Post-B) |
| 15 | screen_detail_SC-XXX.md | {{STATUS}} | {{L1}} | {{L2}} | {{L3}} | 06_screen_design/details/ (Post-B) |
| 16 | coding_standards.md | {{STATUS}} | {{L1}} | {{L2}} | {{L3}} | 07_implementation/ (Wave C: impl-standards) |
| 17 | environment.md | {{STATUS}} | {{L1}} | {{L2}} | {{L3}} | 07_implementation/ (Wave C: impl-standards) |
| 18 | test_strategy.md | {{STATUS}} | {{L1}} | {{L2}} | {{L3}} | 07_implementation/ (Wave C: impl-test) |
| 19 | test_plan.md | {{STATUS}} | {{L1}} | {{L2}} | {{L3}} | 07_implementation/ (Wave C: impl-test) |
| 20 | traceability_matrix.md | {{STATUS}} | {{L1}} | {{L2}} | {{L3}} | 07_implementation/ (Wave C: impl-test) |
| 21 | nonfunctional_test_plan.md | {{STATUS}} | {{L1}} | {{L2}} | {{L3}} | 07_implementation/ (Wave C: impl-test) |
| 22 | operations.md | {{STATUS}} | {{L1}} | {{L2}} | {{L3}} | 07_implementation/ (Wave C: impl-ops) |
| 23 | observability_design.md | {{STATUS}} | {{L1}} | {{L2}} | {{L3}} | 07_implementation/ (Wave C: impl-ops) |
| 24 | incident_response.md | {{STATUS}} | {{L1}} | {{L2}} | {{L3}} | 07_implementation/ (Wave C: impl-ops) |
| 25 | backup_restore_dr.md | {{STATUS}} | {{L1}} | {{L2}} | {{L3}} | 07_implementation/ (条件付き: sla_tier≠basic) |
| 26 | migration_plan.md | {{STATUS}} | {{L1}} | {{L2}} | {{L3}} | 07_implementation/ (条件付き: has_migration=true) |

---

## 完了率

| カテゴリ | 完了数 | 総数 | 完了率 |
|---------|--------|------|--------|
| project/ | {{COMPLETE}} | {{TOTAL}} | {{RATE}} |
| docs/requirements/ | {{COMPLETE}} | {{TOTAL}} | {{RATE}} |
| design/ | {{COMPLETE}} | {{TOTAL}} | {{RATE}} |
| api/ | {{COMPLETE}} | {{TOTAL}} | {{RATE}} |
| database/ | {{COMPLETE}} | {{TOTAL}} | {{RATE}} |
| architecture/ | {{COMPLETE}} | {{TOTAL}} | {{RATE}} |
| implementation/ | {{COMPLETE}} | {{TOTAL}} | {{RATE}} |
| **合計** | **{{TOTAL_COMPLETE}}** | **{{GRAND_TOTAL}}** | **{{TOTAL_RATE}}** |

---

## ID体系サマリー

| ID種別 | 定義数 | 参照数 | カバレッジ |
|--------|--------|--------|-----------|
| FR-XXX | {{FR_DEF}} | {{FR_REF}} | {{FR_COV}} |
| NFR-XXX | {{NFR_DEF}} | {{NFR_REF}} | {{NFR_COV}} |
| SC-XXX | {{SC_DEF}} | {{SC_REF}} | {{SC_COV}} |
| API-XXX | {{API_DEF}} | {{API_REF}} | {{API_COV}} |
| ENT-XXX | {{ENT_DEF}} | {{ENT_REF}} | {{ENT_COV}} |
| ADR-XXXX | {{ADR_DEF}} | {{ADR_REF}} | {{ADR_COV}} |

---

## 運用準備サマリー

| 項目 | 状態 | 備考 |
|------|------|------|
| SLI/SLO 定義 | {{OPS_SLI_STATUS}} | observability_design.md |
| テスト戦略・計画 | {{OPS_TEST_STATUS}} | test_strategy.md, test_plan.md |
| NFR 測定可能性 | {{OPS_NFR_STATUS}} | nonfunctional_test_plan.md |
| トレーサビリティ | {{OPS_TRACE_STATUS}} | traceability_matrix.md |
| バックアップ/DR | {{OPS_DR_STATUS}} | backup_restore_dr.md |
| インシデント対応 | {{OPS_INCIDENT_STATUS}} | incident_response.md |
| データガバナンス | {{OPS_DATA_STATUS}} | data_structure.md, security.md |

---

## 残課題

### ❌ BLOCKER

| # | 課題内容 | 対象ドキュメント |
|---|----------|-----------------|
| 1 | {{課題内容}} | {{対象ドキュメント}} |

### ⚠️ WARNING

| # | 課題内容 | 対象ドキュメント |
|---|----------|-----------------|
| 1 | {{課題内容}} | {{対象ドキュメント}} |

---

## 推奨事項

{{RECOMMENDATIONS}}

---

## 次のステップ

| # | アクション | 担当 | 期限 |
|---|-----------|------|------|
| 1 | {{アクション}} | {{担当}} | {{期限}} |

---

## 結論

{{CONCLUSION}}
