# Blueprint ログスキーマ（bl-*.yaml）

SessionEnd Hook で自動生成されるログファイルのスキーマ定義。

## ファイル命名規則

```
~/.claude/blueprint-logs/bl-{YYYYMMDD}-{SEQ}.yaml
```

- `YYYYMMDD`: 収集日
- `SEQ`: 3 桁の連番（001, 002, ...）

## スキーマ定義

```yaml
# === 識別 ===
id: string                     # 必須。bl-YYYYMMDD-NNN 形式
created_at: string             # 必須。ISO 8601 UTC
session_id: string             # 必須。Claude Code セッション ID
project_root: string           # 必須。プロジェクトの絶対パス
project_name: string           # 必須。リポジトリ名 or ディレクトリ名

# === パイプライン情報 ===
pipeline:
  stages_executed: string[]    # 必須。実行されたステージ名の配列
                               # 値: spec, test-from-contract, implement, generate-docs
  final_status: string         # 必須。completed | partial | failed | unknown
  pipeline_state_present: bool # 必須。pipeline-state.yaml の存在有無

# === Gate findings（pipeline-state.yaml から抽出） ===
gate_results:                  # 配列。pipeline_state_present=false の場合は空配列
  - gate: string               # contract | test | code | doc
    status: string             # passed | revise
    cycles: number             # Gate サイクル数（1-3）
    counts:
      p0: number               # P0 指摘数
      p1: number               # P1 指摘数
      p2: number               # P2 指摘数
    findings:                  # P0/P1 のみ詳細記録。P2 は counts のみ
      - severity: string       # P0 | P1
        message: string        # 指摘内容
        category: string       # missing_constraint, naming, etc.
        disposition: string    # null | false_positive | downgraded | deferred | wont_fix

# === エラーパターン（transcript 補助抽出） ===
errors:                        # 配列。最大 20 件
  - phase: string              # ツール名 or "unknown"
    type: string               # tool_error
    message: string            # エラーメッセージ（最大 200 文字）

# === ユーザー修正（transcript 補助抽出） ===
user_corrections:
  count: number                # 必須。修正検出数
  items:                       # 配列。最大 10 件
    - stage: string            # 関連ステージ名 or "unknown"
      description: string      # 修正内容の抜粋

# === セッション統計（transcript 補助抽出） ===
stats:
  message_count: number        # 必須。transcript 総行数
  tool_uses: number            # 必須。ツール使用回数
  code_changes: number         # 必須。Write/Edit 回数

# === 重複防止 ===
fingerprint: string            # 必須。session_id + pipeline hash
analysis_range: string         # 分析時に設定。"bl-xxx ~ bl-yyy"
pr_url: string                 # PR 作成時に設定。GitHub PR URL
log_schema_version: string     # 必須。"1.0"

# === トリアージ ===
triage:
  status: string               # 必須。open | analyzed | pr_created
  analyzed_at: string          # 分析完了時に設定。ISO 8601

# === プライバシー ===
privacy:
  redacted: bool               # 必須。匿名化済みか
  expires_at: string           # 必須。TTL（デフォルト: 作成日 + 90 日）
  opt_out: bool                # 必須。収集拒否フラグ
```

## triage.status の遷移

```
open → analyzed → pr_created
```

- `open`: 収集済み、未分析
- `analyzed`: `/blueprint-improve` で分析済み
- `pr_created`: 改善 PR が作成済み
