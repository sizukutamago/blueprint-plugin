# 整合性チェック結果

---

## チェック情報

| 項目 | 内容 |
|------|------|
| チェック日 | {{CHECK_DATE}} |
| 対象ドキュメント | 全ドキュメント |
| チェック担当者 | {{CHECKER}} |
| 総合判定 | {{OVERALL_RESULT}} |

総合判定の凡例: ✅ PASS / ⚠️ ROLLBACK_P1 / ❌ ROLLBACK_P0

---

## 指摘サマリー

| 重大度 | 指摘数 | 判定 | 差し戻し先 |
|--------|-------|------|-----------|
| **P0 (Critical)** | {{P0_COUNT}} | {{P0_STATUS}} | {{P0_TARGET}} |
| **P1 (Major)** | {{P1_COUNT}} | {{P1_STATUS}} | {{P1_TARGET}} |
| **P2 (Minor)** | {{P2_COUNT}} | {{P2_STATUS}} | - |

---

## ID整合性チェック

### 重複ID

| 重大度 | ID | 出現箇所 |
|-------|----|----------|
| {{SEVERITY}} | {{DUPLICATE_ID}} | {{出現箇所}} |

### 孤児ID（参照されていないID）

| 重大度 | ID | 定義箇所 |
|-------|----|----------|
| {{SEVERITY}} | {{ORPHAN_ID}} | {{定義箇所}} |

---

## 出力ファイル完全性チェック

### Phase 1-2: Requirements (web-requirements)

| ファイル | 状態 | 備考 |
|---------|------|------|
| docs/requirements/user-stories.md | {{P1_2_FILE1_STATUS}} | |
| docs/requirements/context_unified.md | {{P1_2_FILE2_STATUS}} | |
| docs/requirements/story_map.md | {{P1_2_FILE3_STATUS}} | |

### Phase 3: Architecture

| ファイル | 状態 | Wave |
|---------|------|------|
| docs/03_architecture/architecture.md | {{P3_FILE1_STATUS}} | A (Skeleton) |
| docs/03_architecture/adr.md | {{P3_FILE2_STATUS}} | A (Skeleton) |
| docs/03_architecture/security.md | {{P3_FILE3_STATUS}} | post-B (Detail) |
| docs/03_architecture/infrastructure.md | {{P3_FILE4_STATUS}} | post-B (Detail) |

### Phase 4: Database (Wave A)

| ファイル | 状態 |
|---------|------|
| docs/04_data_structure/data_structure.md | {{P4_FILE1_STATUS}} |

### Phase 5: API (Wave B)

| ファイル | 状態 |
|---------|------|
| docs/05_api_design/api_design.md | {{P5_FILE1_STATUS}} |
| docs/05_api_design/integration.md | {{P5_FILE2_STATUS}} |

### Phase 6: Design

| ファイル | 状態 | Wave |
|---------|------|------|
| docs/06_screen_design/screen_list.md | {{P6_FILE1_STATUS}} | A (Inventory) |
| docs/06_screen_design/screen_transition.md | {{P6_FILE2_STATUS}} | A (Inventory) |
| docs/06_screen_design/component_catalog.md | {{P6_FILE3_STATUS}} | post-B (Detail) |
| docs/06_screen_design/error_patterns.md | {{P6_FILE4_STATUS}} | post-B (Detail) |
| docs/06_screen_design/ui_testing_strategy.md | {{P6_FILE5_STATUS}} | post-B (Detail) |

### Phase 7: Implementation (Wave C)

| ファイル | 状態 | Teammate | 生成条件 |
|---------|------|----------|---------|
| docs/07_implementation/coding_standards.md | {{P7_FILE1_STATUS}} | impl-standards | 常時 |
| docs/07_implementation/environment.md | {{P7_FILE2_STATUS}} | impl-standards | 常時 |
| docs/07_implementation/test_strategy.md | {{P7_FILE3_STATUS}} | impl-test | 常時 |
| docs/07_implementation/test_plan.md | {{P7_FILE4_STATUS}} | impl-test | 常時 |
| docs/07_implementation/traceability_matrix.md | {{P7_FILE5_STATUS}} | impl-test | 常時 |
| docs/07_implementation/nonfunctional_test_plan.md | {{P7_FILE6_STATUS}} | impl-test | 常時 |
| docs/07_implementation/operations.md | {{P7_FILE7_STATUS}} | impl-ops | 常時 |
| docs/07_implementation/observability_design.md | {{P7_FILE8_STATUS}} | impl-ops | 常時 |
| docs/07_implementation/incident_response.md | {{P7_FILE9_STATUS}} | impl-ops | 常時 |
| docs/07_implementation/backup_restore_dr.md | {{P7_FILE10_STATUS}} | impl-ops | sla_tier ≠ basic |
| docs/07_implementation/migration_plan.md | {{P7_FILE11_STATUS}} | impl-ops | has_migration = true |

### ファイル完全性サマリー

| フェーズ | 状態 | 不足数 | 重大度 |
|---------|------|--------|-------|
| Phase 1-2: Requirements | {{P1_2_STATUS}} | {{P1_2_MISSING}} | P0 |
| Phase 3: Architecture | {{P3_STATUS}} | {{P3_MISSING}} | P1 |
| Phase 4: Database | {{P4_STATUS}} | {{P4_MISSING}} | P1 |
| Phase 5: API | {{P5_STATUS}} | {{P5_MISSING}} | P1 |
| Phase 6: Design | {{P6_STATUS}} | {{P6_MISSING}} | P1 |
| Phase 7: Implementation | {{P7_STATUS}} | {{P7_MISSING}} | P1 |

---

## 画面詳細ファイル完全性チェック (Phase 6b)

| SC-ID | 画面名 | 状態 | 重大度 |
|-------|--------|------|-------|
| {{SC_ID}} | {{SCREEN_NAME}} | {{FILE_STATUS}} | P1 |

---

## 設計スコープ整合性チェック

### Goals/Non-Goals と FR の整合性

| Goals項目 | 対応FR | 整合性 | 重大度 |
|----------|--------|--------|-------|
| {{GOAL}} | {{RELATED_FR}} | ✅/⚠️/❌ | P0 |

### エラーパターンと Architecture の整合性

| エラーカテゴリ | 整合性 | 重大度 |
|--------------|--------|-------|
| User Errors (4xx) | ✅/⚠️ | P1 |
| System Errors (5xx) | ✅/⚠️ | P1 |

---

## トレーサビリティマトリクス

| FR ID | 関連SC | 関連API | 関連ENT | 状態 | 重大度 |
|-------|--------|---------|---------|------|-------|
| {{FR_ID}} | {{SC_IDS}} | {{API_IDS}} | {{ENT_IDS}} | {{STATUS}} | P1 |

---

## 運用準備チェック (Level 5)

| # | チェック項目 | 状態 | 重大度 | 参照ファイル |
|---|-------------|------|--------|------------|
| 1 | SLI/SLO 定義 | {{OPS_CHECK1}} | P1 | observability_design.md |
| 2 | テスト完了基準（定量） | {{OPS_CHECK2}} | P1 | test_plan.md |
| 3 | NFR 測定方法+合否基準 | {{OPS_CHECK3}} | P1 | nonfunctional_test_plan.md |
| 4 | トレーサビリティマトリクス | {{OPS_CHECK4}} | P1 | traceability_matrix.md |
| 5 | バックアップ/リストア手順 | {{OPS_CHECK5}} | P1 | backup_restore_dr.md |
| 6 | 移行計画（brownfield） | {{OPS_CHECK6}} | P1 | migration_plan.md |
| 7 | ロールバック手順 | {{OPS_CHECK7}} | P1 | operations.md |
| 8 | 監視アラート設計 | {{OPS_CHECK8}} | P2 | observability_design.md |
| 9 | インシデント対応計画 | {{OPS_CHECK9}} | P2 | incident_response.md |
| 10 | データ分類（全ENT） | {{OPS_CHECK10}} | P2 | data_structure.md |

---

## 詳細指摘事項

### ❌ P0: Critical (web-requirements へ差し戻し)

| # | 指摘内容 | 根拠 |
|---|----------|------|
| 1 | {{P0_ISSUE}} | {{EVIDENCE}} |

### ⚠️ P1: Major (Wave A/B 各フェーズへ差し戻し)

| # | 指摘内容 | 差し戻し先 |
|---|----------|-----------|
| 1 | {{P1_ISSUE}} | {{TARGET_PHASE}} |

### ℹ️ P2: Minor (要対応リスト)

| # | 指摘内容 | 備考 |
|---|----------|------|
| 1 | {{P2_ISSUE}} | {{REMARK}} |

---

## 結論

{{CONCLUSION}}

---

## 良い点

{{GOOD_POINTS}}

---

## 統計情報

| 項目 | 値 |
|------|-----|
| 総ドキュメント数 | {{TOTAL_DOCS}} |
| 総ID数 | {{TOTAL_IDS}} |
| 整合性エラー数 | {{ERROR_COUNT}} |
| 警告数 | {{WARNING_COUNT}} |

---

## 結論

{{CONCLUSION}}
