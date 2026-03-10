# Self-Improve 分析ポリシー

blueprint パイプラインの使用ログを分析し、改善機会を特定するためのポリシー定義。
Platform 非依存の分析ルールのみ記述する。Hook 設定や PR 作成手順は含めない。

## 分析対象データ

### 1. Gate findings

Review Gate で検出された P0/P1/P2 指摘。
- **P0/P1 のみ詳細分析の対象**（P2 は件数集計のみ）
- disposition（false_positive, downgraded, deferred, wont_fix）を考慮
- 同一 category の反復を重視

### 2. エラーパターン

パイプライン実行中に発生したツールエラー。
- phase（implementer, integrator, refactorer, gate）で分類
- type（test_failure, parse_error, circular_dep, timeout）で分類

### 3. ユーザー修正

ユーザーが生成結果を手動で修正した頻度とパターン。
- stage 別の修正頻度
- 修正内容のカテゴリ分類

## パターン検出ルール

### recurring_findings（反復指摘）

| 条件 | 判定 | 優先度 |
|------|------|--------|
| 同一 category が 5 回以上 | 高優先パターン | high |
| 同一 category が 3 回以上 | 中優先パターン | medium |
| 同一 category が 2 回以上（P0/P1） | 低優先パターン | low |

### common_errors（頻出エラー）

| 条件 | 判定 | 優先度 |
|------|------|--------|
| 同一 type が 3 回以上 | 対策必須 | high |
| 同一 phase で 3 回以上 | 改善推奨 | medium |

### user_corrections（ユーザー修正パターン）

| 条件 | 判定 | 優先度 |
|------|------|--------|
| 同一 stage で 3 回以上 | 生成品質の問題 | high |
| 全体で 5 回以上 | 改善推奨 | medium |

## 改善案の優先度判定

### Impact x Effort マトリクス

| | Effort: Low | Effort: Medium | Effort: High |
|---|---|---|---|
| **Impact: High** | P1（最優先） | P1 | P2 |
| **Impact: Medium** | P1 | P2 | P3 |
| **Impact: Low** | P2 | P3 | 見送り |

### Impact 判定基準

- **High**: 同一パターン 5 件以上、または P0 指摘に関連
- **Medium**: 同一パターン 3-4 件、または P1 指摘に関連
- **Low**: 同一パターン 2 件、または P2 指摘のみ

### Effort 判定基準

- **Low**: テンプレート修正、レビュー基準追加（1 ファイル変更）
- **Medium**: SKILL.md ワークフロー修正、defaults 更新（2-3 ファイル変更）
- **High**: core 仕様変更、複数ステージに跨る修正（4 ファイル以上）

## 改善案のカテゴリ

| カテゴリ | 対象ファイル例 | 説明 |
|---------|---------------|------|
| template_update | `skills/*/references/` | テンプレート・サンプルの改善 |
| review_criteria_update | `core/review-criteria.md` | レビュー基準の追加・修正 |
| spec_update | `core/spec.md` | /spec ワークフローの改善 |
| default_update | `core/defaults/` | 実装規約の更新 |
| skill_update | `skills/*/SKILL.md` | スキル実行手順の改善 |
| schema_update | `core/contract-schema.md` | Contract スキーマの拡張 |

## ログ保持ポリシー

| 項目 | 値 | 説明 |
|------|-----|------|
| TTL | 90 日 | expires_at 以降は自動削除対象 |
| 匿名化 | project_root を basename に置換 | 分析時に自動適用 |
| opt-out | `privacy.opt_out: true` | ユーザーが収集を拒否した場合 |
| 保存先 | `~/.claude/blueprint-logs/` | ユーザーローカル |

### 期限切れログの扱い

- `expires_at` を過ぎたログは分析対象から除外
- 削除は `/blueprint-improve --cleanup` で手動実行（自動削除はしない）
- 分析済み（`triage.status: analyzed` 以降）のログは TTL に関わらず保持
