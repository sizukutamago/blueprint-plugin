---
name: review
description: This skill should be used when the user asks to "review design documents", "check document consistency", "validate traceability", "generate completion summary", "audit design specifications", or "check ID consistency". Performs consistency checks and reviews on design documentation with P0/P1/P2 severity-based Gate judgment.
version: 3.2.0
---

# Review Skill

設計書の整合性チェック・レビューを行うスキル。
構造チェック、相互参照検証、完全性確認を実施し、
**P0/P1/P2 重大度による Gate 判定**でプロジェクト完了サマリーを生成する。

## 重大度分類（P0/P1/P2）

| 重大度 | 旧分類 | 定義 | 差し戻し先 | Gate 判定 |
|--------|--------|------|-----------|----------|
| **P0** | BLOCKER | 要件不充足、根本的設計ミス | web-requirements | 即差し戻し |
| **P1** | BLOCKER | セクション間不整合（DB/API等） | Wave A/B（該当フェーズ） | 2件以上で差し戻し |
| **P2** | WARNING | 記述不足、フォーマット違反 | 要対応リストに記録（通過） | 通過（要対応リスト記録） |

### P0 指摘例（即差し戻し）
- FR に対応する機能が全く実装されていない
- 要件定義で承認された機能が設計から欠落
- 根本的なアーキテクチャ選択ミス
- ユーザー承認済み技術スタック（mode: specified）と設計結果の不一致（ユーザー制約違反）

### P1 指摘例（整合性問題）
- API で未定義の ENT-XXX を参照
- 画面詳細で未定義の API-XXX を参照
- NFR で定義されたセキュリティ要件が未実装
- ユーザー承認済み技術スタックの補完部分（自律選定したカテゴリ）に互換性問題がある

### P2 指摘例（軽微な問題）
- 「など」「適切に」等の曖昧表現
- プレースホルダー `{{}}` 残存
- Gherkin 形式の軽微な不備

## 前提条件

| 条件 | 必須 | 説明 |
|------|------|------|
| docs/ 配下の設計書 | ○ | レビュー対象 |
| docs/project-context.yaml | △ | ID・トレーサビリティ情報 |

## 出力ファイル

| ファイル | テンプレート | 説明 |
|---------|-------------|------|
| docs/08_review/consistency_check.md | {baseDir}/references/consistency_check.md | 整合性チェック結果 |
| docs/08_review/project_completion.md | {baseDir}/references/project_completion.md | 完了サマリー |

**参照テンプレート**（成果物としては生成しない）: `{baseDir}/references/review_template.md`（個別レビュー時の書式参考用）

## 依存関係

| 種別 | 対象 |
|------|------|
| 前提スキル | 全スキル（最終フェーズ） |
| 後続スキル | なし |

## ワークフロー

```
1. 全設計書を読み込み
2. Level 1: 構造チェック
3. Level 2: 整合性チェック
4. Level 3: 完全性チェック
5. Level 4: 出力ファイル完全性チェック
6. Level 5: 運用準備チェック（IPA準拠）
7. 問題を分類（P0/P1/P2）
8. consistency_check.md を生成
9. project_completion.md を生成
```

## レビューレベル

### Level 1: 構造チェック

| チェック項目 |
|-------------|
| YAMLフロントマター存在 |
| 必須セクション存在 |
| 見出し階層が適切 |
| テーブル形式が正しい |

### Level 2: 整合性チェック

| チェック項目 |
|-------------|
| ID形式準拠（FR-XXX, SC-XXX等） |
| 重複ID無し |
| 孤児ID無し |
| 参照先存在 |
| 用語統一（glossary準拠） |
| Goals/Non-Goals と FR の整合性 |
| エラーパターンと architecture の整合性 |
| テスト戦略と implementation の整合性 |
| 技術スタックがユーザー承認内容と一致（`mode: specified` の場合のみ。`project.constraints.approved_tech_stack` vs `blackboard.decisions.architecture.tech_stack`） |

### Level 3: 完全性チェック

| チェック項目 |
|-------------|
| プレースホルダー `{{}}` 残存無し |
| 必須項目が全て記入済 |
| 詳細仕様が記載されている |
| 受入基準が検証可能 |
| **画面詳細ファイル完全性** |

### Level 4: 出力ファイル完全性チェック

全フェーズの必須出力ファイルが存在するかをチェックする。

#### 必須ファイル一覧

| フェーズ | 必須ファイル | Wave |
|---------|-------------|------|
| Phase 1-2: Requirements | `docs/requirements/user-stories.md`, `context_unified.md`, `story_map.md` | - |
| Phase 3a: Arch Skeleton | `03_architecture/architecture.md`, `adr.md` | A |
| Phase 3b: Arch Detail | `03_architecture/security.md`, `infrastructure.md`, `cache_strategy.md` | B |
| Phase 4: Database | `04_data_structure/data_structure.md` | A |
| Phase 5: API | `05_api_design/api_design.md`, `integration.md` | B |
| Phase 6a: Screen Inventory | `06_screen_design/screen_list.md`, `screen_transition.md` | A |
| Phase 6b: Screen Detail | `06_screen_design/component_catalog.md`, `error_patterns.md`, `ui_testing_strategy.md`, `details/screen_detail_SC-XXX.md` (全SC-ID分) | post-B |
| Phase 7a: Impl Standards | `07_implementation/coding_standards.md`, `environment.md` | Wave C |
| Phase 7b: Impl Test | `07_implementation/test_strategy.md`, `test_plan.md`, `traceability_matrix.md`, `nonfunctional_test_plan.md` | Wave C |
| Phase 7c: Impl Ops | `07_implementation/operations.md`, `observability_design.md`, `incident_response.md` | Wave C |
| Phase 7c: Impl Ops (条件付き) | `07_implementation/backup_restore_dr.md` (sla_tier≠basic), `migration_plan.md` (has_migration=true) | Wave C |
| Phase 8: Review | `08_review/consistency_check.md`, `project_completion.md` | - |

**注意**: Phase 1-2 は `web-requirements` スキルが生成。旧形式（`01_hearing/`, `02_requirements/`）は非推奨。

#### 画面詳細ファイル完全性

| チェック項目 | 説明 |
|-------------|------|
| 全SC-IDに対応するファイル存在 | screen_list.md内の全SC-IDに対してscreen_detail_SC-XXX.mdが存在 |
| ファイル命名規則準拠 | `screen_detail_SC-XXX.md` 形式 |
| 必須セクション存在 | 基本情報、画面レイアウト、コンポーネント構成、状態管理、ユーザー操作、API連携 |

**検証手順**:
```
1. 各フェーズの必須ファイルが存在するか確認
2. screen_list.md から全SC-IDを抽出
3. details/ ディレクトリ内のファイルを列挙
4. 不足ファイルを P1 として報告
```

### Level 5: 運用準備チェック（IPA準拠）

| チェック項目 | 重大度 | 参照ファイル | 生成条件 |
|-------------|--------|------------|---------|
| SLI/SLO が定義されている | P1 | observability_design.md | 常時 |
| テスト完了基準が定量的に定義 | P1 | test_plan.md | 常時 |
| NFR に測定方法と合否基準がある | P1 | nonfunctional_test_plan.md | 常時 |
| トレーサビリティマトリクスが完備 | P1 | traceability_matrix.md | 常時 |
| バックアップ/リストア手順が存在 | P1 | backup_restore_dr.md | sla_tier ≠ basic |
| 移行計画が存在（brownfield の場合） | P1 | migration_plan.md | has_migration = true |
| ロールバック手順が定義されている | P1 | operations.md | 常時 |
| 監視アラートが設計されている | P2 | observability_design.md | 常時 |
| インシデント対応計画が存在 | P2 | incident_response.md | 常時 |
| データ分類が全エンティティに定義 | P2 | data_structure.md | 常時 |

**条件付きチェック**: project-context.yaml の `project.profile` を参照し、生成条件に合致するファイルのみチェック対象とする。

**profile 未設定時のデフォルト動作**: `project.profile` が未設定の場合は `sla_tier: basic`, `has_migration: false` として扱う（backup_restore_dr.md, migration_plan.md はチェック対象外）。profile の未設定自体を P2 として記録する。

## トレーサビリティチェック

- 全FRに対応するSCが存在
- 画面操作に対応するAPIが存在
- APIレスポンスのENTが定義済

## Gate 判定基準

| 判定 | 条件 | アクション |
|------|------|-----------|
| ✅ **PASS** | P0=0, P1≤1, P2任意 | 完了、P2 は要対応リストに記録 |
| ⚠️ **ROLLBACK_P1** | P0=0, P1≥2 | Wave A/B の該当フェーズへ差し戻し |
| ❌ **ROLLBACK_P0** | P0≥1 | web-requirements へ即差し戻し |

## 問題分類（P0/P1/P2 マッピング）

| 重大度 | 旧分類 | 例 | 差し戻し先 |
|--------|--------|-----|-----------|
| P0 | BLOCKER | FR 対応機能欠落、根本設計ミス | `web-requirements` |
| P1 | BLOCKER | 参照先不在（ENT/API/SC）、重複ID、必須ファイル不足 | 該当 Wave フェーズ |
| P2 | WARNING | 孤児ID、プレースホルダー残存、曖昧表現 | 当該エージェント（記録のみ） |

## 差し戻しロジック

| 指摘カテゴリ | 重大度 | 差し戻し先 | 例 |
|-------------|--------|-----------|-----|
| 未定義 ENT 参照 | P1 | database (Wave A) | API で未定義の ENT-XXX を参照 |
| API 参照切れ | P1 | api (Wave B) | 画面詳細で未定義の API-XXX を参照 |
| 画面 ID 不整合 | P1 | design-inventory (Wave A) | 遷移図に未定義の SC-XXX |
| NFR 未対応 | P1 | architecture-skeleton (Wave A) | セキュリティ要件が未実装 |
| 技術スタック不整合（mode: specified 時） | P0 | architecture-skeleton (Wave A) | ユーザー指定技術が設計結果に反映されていない |
| 要件対応漏れ | P0 | web-requirements | FR-XXX に対応する機能が全く存在しない |
| 形式エラー | P2 | 当該フェーズ | Gherkin 形式不正 |
| 曖昧表現 | P2 | 当該フェーズ | 「など」「適切に」 |

## 修正サイクル

```
レビュー結果: 問題あり
    ↓
重大度を判定（P0/P1/P2）
    ↓
P0: web-requirements へ差し戻し
P1: 該当 Wave フェーズへ差し戻し
P2: 要対応リストに記録、通過
    ↓
差し戻し先で修正
    ↓
再レビュー（最大3回）
    ↓
3回超過: ユーザー介入要請
```

## SendMessage 完了報告（Gate 結果）

Gate 判定結果を以下の YAML 形式で Lead に SendMessage を送信する:

```yaml
status: ok | conflict
severity: null | P0 | P1
artifacts:
  - docs/08_review/consistency_check.md
  - docs/08_review/project_completion.md
gate:
  overall: PASS | ROLLBACK_P1 | ROLLBACK_P0
  p0_count: 0
  p1_count: 0
  p2_count: 0
  rollback_targets:
    - phase: database
      reason: "API-003 が参照する ENT-Order が未定義"
  p2_items:
    - "詳細仕様に「など」が残存"
contract_outputs: []
open_questions: []
blockers:
  - "P0: FR-003 に対応する API が未定義"
```

**注意**: project-context.yaml には直接書き込まない（Aggregator の責務）。

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| 設計書不在 | 存在するファイルのみレビュー、欠落を報告 |
| project-context.yaml 不在 | ファイル単体でチェック、トレーサビリティはスキップ |
| 修正サイクル超過 | 現状で完了、残課題を project_completion.md に記録 |
