# レビュー基準と Gate 判定

## 重大度分類（P0/P1/P2）

| 重大度 | 定義 | 差し戻し先 | Gate 判定 |
|--------|------|-----------|----------|
| **P0** | 要件不充足、根本的設計ミス | web-requirements | 即差し戻し |
| **P1** | セクション間不整合（DB/API等） | Wave A/B（該当フェーズ） | 2件以上で差し戻し |
| **P2** | 記述不足、フォーマット違反 | 要対応リストに記録（通過） | 通過（要対応リスト記録） |

### P0 指摘例（即差し戻し）
- FR に対応する機能が全く実装されていない
- 要件定義で承認された機能が設計から欠落
- 根本的なアーキテクチャ選択ミス
- ユーザー承認済み技術スタック（mode: specified）と設計結果の不一致

### P1 指摘例（整合性問題）
- API で未定義の ENT-XXX を参照
- 画面詳細で未定義の API-XXX を参照
- NFR で定義されたセキュリティ要件が未実装
- 必須ファイルの欠落

### P2 指摘例（軽微な問題）
- 「など」「適切に」等の曖昧表現
- プレースホルダー `{{}}` 残存
- Gherkin 形式の軽微な不備

## 5 段階レビューチェック

### Level 1: 構造チェック
- YAML フロントマター存在
- 必須セクション存在
- 見出し階層が適切
- テーブル形式が正しい

### Level 2: 整合性チェック
- ID 形式準拠（FR-XXX, SC-XXX 等）
- 重複 ID 無し
- 孤児 ID 無し（定義されているが参照されていない ID）
- 参照先存在
- 用語統一（glossary 準拠）
- Goals/Non-Goals と FR の整合性
- 技術スタックがユーザー承認内容と一致（`mode: specified` の場合）

### Level 3: 完全性チェック
- プレースホルダー `{{}}` 残存無し
- 必須項目が全て記入済
- 詳細仕様が記載されている
- 受入基準が検証可能
- 画面詳細ファイル完全性（全 SC-ID に対応するファイル存在）

### Level 4: 出力ファイル完全性チェック

全フェーズの必須出力ファイルが存在するかをチェック。
必須ファイル一覧は `core/output-structure.md` を参照。

### Level 5: 運用準備チェック（IPA 準拠）

| チェック項目 | 重大度 | 参照ファイル | 生成条件 |
|-------------|--------|------------|---------|
| SLI/SLO が定義されている | P1 | observability_design.md | 常時 |
| テスト完了基準が定量的に定義 | P1 | test_plan.md | 常時 |
| NFR に測定方法と合否基準がある | P1 | nonfunctional_test_plan.md | 常時 |
| トレーサビリティマトリクスが完備 | P1 | traceability_matrix.md | 常時 |
| バックアップ/リストア手順が存在 | P1 | backup_restore_dr.md | sla_tier != basic |
| 移行計画が存在 | P1 | migration_plan.md | has_migration = true |
| ロールバック手順が定義されている | P1 | operations.md | 常時 |
| 監視アラートが設計されている | P2 | observability_design.md | 常時 |
| インシデント対応計画が存在 | P2 | incident_response.md | 常時 |
| データ分類が全エンティティに定義 | P2 | data_structure.md | 常時 |

**条件付きチェック**: `project.profile` を参照し、生成条件に合致するファイルのみチェック対象とする。
**profile 未設定時**: `sla_tier: basic`, `has_migration: false` として扱い、P2 として記録。

## Severity ガバナンスルール

### P1→P2 格下げルール

P1 finding を P2 に格下げするには以下の**すべて**を満たす必要がある:

| 条件 | 説明 |
|------|------|
| 正当化理由 | 「プロジェクト固有の事情で影響度が低い」等の具体的理由が必要 |
| 記録義務 | 格下げの理由を findings の `disposition_reason` フィールドに記載（`disposition: downgraded` を設定） |
| 影響範囲の確認 | 格下げが他のステージ/成果物に波及しないことを確認 |

**禁止される格下げ**:
- 「テストで検証されるから」— テストの存在は P1 の正当化にならない（テスト自体が不完全な可能性）
- 「後で直すから」— 修正予定は格下げ理由にならない
- 「小さな差異だから」— 差異の大小ではなく整合性の有無で判定

**正当な格下げ例**:
- Contract に定義があるが、プロジェクト要件で明示的に対象外とされた機能
- 外部サービスの制約により Contract 通りの実装が不可能（代替実装がある）
- deprecated な Contract フィールド（status: deprecated）

### False Positive（誤検出）の扱い

レビューエージェントが報告した finding が実際には問題でない場合:

| ステータス | 説明 | 記録方法 |
|-----------|------|---------|
| `acknowledged` | 誤検出として認知、記録を保持 | findings に `disposition: false_positive` + 理由を記載 |
| `wont_fix` | 既知の問題だが修正しない | findings に `disposition: wont_fix` + 理由を記載 |

**重要**: False positive は**削除しない**。監査証跡として記録を残す。
REVISE サイクルのカウントからは除外する（修正不要のため）。

### findings 記録フォーマット（拡張）

```yaml
findings:
  - severity: P1
    target: "CON-xxx"
    field: "input.body.quantity.max"
    message: "max 制約が未定義"
    suggestion: "max: 99 等の上限を追加"
    disposition: null          # null | false_positive | wont_fix | downgraded
    disposition_reason: null   # disposition が null でない場合は必須
    original_severity: null    # downgraded の場合、元の severity を記録
```

## Gate 判定基準

| 判定 | 条件 | アクション |
|------|------|-----------|
| **PASS** | P0=0, P1<=1, P2 任意 | 完了。P2 は要対応リストに記録 |
| **ROLLBACK_P1** | P0=0, P1>=2 | Wave A/B の該当フェーズへ差し戻し |
| **ROLLBACK_P0** | P0>=1 | web-requirements へ即差し戻し |

## 差し戻しロジック

| 指摘カテゴリ | 重大度 | 差し戻し先 |
|-------------|--------|-----------|
| 未定義 ENT 参照 | P1 | database (Wave A) |
| API 参照切れ | P1 | api (Wave B) |
| 画面 ID 不整合 | P1 | design-inventory (Wave A) |
| NFR 未対応 | P1 | architecture-skeleton (Wave A) |
| 技術スタック不整合（mode: specified 時） | P0 | architecture-skeleton (Wave A) |
| 要件対応漏れ | P0 | web-requirements |
| 形式エラー | P2 | 当該フェーズ |
| 曖昧表現 | P2 | 当該フェーズ |

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
