# 分析サマリースキーマ（analysis-*.yaml）

`/blueprint-improve` の分析結果を保存するスキーマ定義。

## ファイル命名規則

```
~/.claude/blueprint-logs/analysis/analysis-{YYYYMMDD}.yaml
```

## スキーマ定義

```yaml
# === 識別 ===
analyzed_at: string            # 必須。ISO 8601 UTC
log_range:
  from: string                 # 必須。最古ログの ID（bl-YYYYMMDD-NNN）
  to: string                   # 必須。最新ログの ID
  count: number                # 必須。分析対象ログ数

# === パターン検出結果 ===
patterns:

  # 反復指摘パターン
  recurring_findings:
    - category: string         # missing_constraint, naming, etc.
      count: number            # 出現回数
      severity_distribution:
        p0: number
        p1: number
        p2: number
      affected_gates: string[] # 関連 Gate の配列
      example_messages:        # 代表的な指摘メッセージ（最大 3 件）
        - string
      suggested_improvement: string  # 改善提案テキスト
      target_files:
        - path: string         # 改善対象ファイルパス（blueprint-plugin 相対）
          change_type: string  # template_update | review_criteria_update | etc.

  # 頻出エラーパターン
  common_errors:
    - type: string             # tool_error, test_failure, etc.
      phase: string            # ツール名 or フェーズ名
      count: number
      pattern: string          # エラーの共通パターン説明
      suggested_improvement: string

  # ユーザー修正パターン
  user_corrections:
    - pattern: string          # field_naming, missing_field, etc.
      count: number
      affected_stages: string[]
      description: string      # パターンの説明
      suggested_improvement: string

# === 改善提案 ===
improvements:
  - id: string                 # imp-001 形式
    priority: string           # high | medium | low（Impact x Effort で決定）
    type: string               # template_update | spec_update | review_criteria_update |
                               # default_update | skill_update | schema_update
    target_file: string        # blueprint-plugin 相対パス
    description: string        # 改善内容の説明
    evidence: string           # 根拠（パターン名 + 件数）
    impact: string             # high | medium | low
    effort: string             # low | medium | high

# === メタデータ ===
metadata:
  analyzer_version: string     # "1.0"
  log_schema_version: string   # 分析対象ログのスキーマバージョン
```

## 改善提案の type 定義

| type | 対象 | 例 |
|------|------|-----|
| `template_update` | テンプレート・サンプル | Contract テンプレートにフィールド制約を追加 |
| `review_criteria_update` | レビュー基準 | P1 指摘例を追加 |
| `spec_update` | ワークフロー仕様 | /spec の命名ルール強化 |
| `default_update` | 実装規約 | エラーハンドリングパターンの追加 |
| `skill_update` | スキル実行手順 | 承認ステップの追加 |
| `schema_update` | Contract スキーマ | フィールド制約の必須化 |
