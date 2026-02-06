# Agent-Teams 実行プロトコル

agent-teams による 2-wave 並列実行のライフサイクルと各ロールの責務を定義する。

## 前提条件

- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` が設定済み
- `web-requirements` スキル（dev-tools-plugin）がインストール済み

## ライフサイクル

```
1. Lead → Teammate.spawnTeam("design-docs")
2. Lead → Task(aggregator) をスポーン（常駐、Wave 全体を通じて生存）
3. Lead → web-requirements を実行（Phase 1-2）
4. Lead → ユーザー承認待ち
5. Lead → TaskCreate で DAG（11タスク）を作成
6. Lead → Wave A teammate 3体を並列スポーン
7. Wave A 完了 → Lead → aggregator に統合依頼
8. Aggregator → project-context.yaml 更新 → Lead に報告
9. Lead → Wave A teammate を shutdown
10. Lead → Wave B teammate 2体を並列スポーン
11. Wave B 完了 → Lead → aggregator に統合依頼
12. Aggregator → project-context.yaml 更新 → Lead に報告
13. Lead → Wave B teammate を shutdown
14. Lead → Post-B → implementation → reviewer を順次スポーン
15. Reviewer → Gate 結果を Lead に送信
16. Gate: PASS → cleanup / P1 → 修正サイクル / P0 → ユーザー通知
17. Lead → Teammate.cleanup()
```

## ロール定義

### Lead（オーケストレータ）

**モード**: delegate（ファイル編集不可）

| 責務 | 詳細 |
|------|------|
| チーム管理 | spawnTeam、teammate のスポーン/shutdown |
| DAG 作成 | TaskCreate で 11 タスクと blockedBy を設定 |
| Wave 遷移 | Wave A → Aggregator → Wave B → ... の順序制御 |
| Gate 判定 | reviewer の結果を受けて PASS/ROLLBACK を決定 |
| ユーザー確認 | Phase 2 後の承認、P0 時の通知 |
| コンテキスト渡し | スポーン時にプロンプトで圧縮コンテキストを埋め込み |

### Aggregator（常駐 teammate）

**唯一の Blackboard 書き込み者**（単一ライター原則）

| 責務 | 詳細 |
|------|------|
| Blackboard 更新 | project-context.yaml への書き込み |
| Two-step Reduce | JSON 正規化 + Adjudication Pass |
| 矛盾検出 | 参照先不在、重複 ID、型不整合 |
| コンテキスト圧縮 | 後続 Wave 向けにエンティティ要約 |

**常駐の理由**: Wave A〜B を通じてコンテキストを保持し、
Blackboard の一貫性を担保する。他の teammate は JIT スポーン。

### Teammate（各フェーズ実行者）

**JIT スポーン**: Wave ごとに生成→完了→shutdown

| 責務 | 詳細 |
|------|------|
| スキル実行 | 割り当てられた SKILL.md に従い成果物を生成 |
| ファイル書き込み | 自分の output_dir にのみ書き込む |
| 完了報告 | SendMessage で contract_outputs を Lead に送信 |
| shutdown 待機 | 完了報告後、Lead からの shutdown_request を承認 |

## SendMessage 完了報告フォーマット

各 teammate が完了時に Lead に送信する構造化メッセージ:

```yaml
status: ok | needs_input | conflict | blocked
severity: null | P0 | P1 | P2
artifacts:
  - docs/03_architecture/architecture.md
  - docs/03_architecture/adr.md
contract_outputs:
  - key: decisions.architecture.tech_stack
    value: [Next.js, PostgreSQL, Prisma]
  - key: decisions.architecture.boundaries
    value:
      - name: frontend
        type: SPA
open_questions:
  - "キャッシュ戦略は Wave B で決定"
blockers: []
```

### contract_outputs.key の命名規則

contract_outputs の `key` は**相対キー**として記述する:
- `decisions.architecture.tech_stack` → Aggregator が `blackboard.decisions.architecture.tech_stack` に正規化
- `traceability.fr_to_ent` → Aggregator が `traceability.fr_to_ent` にそのまま書き込み

Aggregator は Step 1（JSON 正規化）で `decisions.*` を `blackboard.decisions.*` にプレフィックス付与する。
`traceability.*` と `id_registry.*` はトップレベルなのでそのまま。

**SendMessage 呼び出し例:**
```
SendMessage({
  type: "message",
  recipient: "lead",
  content: "## Task Complete: architecture-skeleton\n\n```yaml\nstatus: ok\n...\n```",
  summary: "arch-skeleton completed"
})
```

## TaskList DAG 設計

```
task-1:  web-requirements          blockedBy: []        owner: lead
task-2:  architecture-skeleton     blockedBy: [1]       owner: arch-skeleton
task-3:  database                  blockedBy: [1]       owner: database
task-4:  design-inventory          blockedBy: [1]       owner: design-inventory
task-5:  wave-aggregator-a         blockedBy: [2,3,4]   owner: aggregator
task-6:  api                       blockedBy: [5]       owner: api
task-7:  architecture-detail       blockedBy: [5]       owner: arch-detail
task-8:  wave-aggregator-b         blockedBy: [6,7]     owner: aggregator
task-9:  design-detail             blockedBy: [8]       owner: design-detail
task-10: implementation            blockedBy: [9]       owner: implementation
task-11: review                    blockedBy: [10]      owner: reviewer
```

### Task metadata

```yaml
metadata:
  skill: architecture-skeleton
  wave: A
  model: opus
  inputs: [docs/requirements/user-stories.md]
  outputs: [docs/03_architecture/architecture.md, docs/03_architecture/adr.md]
  blackboard_keys: [decisions.architecture.tech_stack, decisions.architecture.boundaries]
```

## コンテキスト渡し戦略

teammate は Lead の会話履歴を継承しない。スポーンプロンプトに全コンテキストを埋め込む。

| Wave | ソース | 圧縮戦略 | 目標 |
|------|--------|----------|------|
| A | docs/requirements/ | Chain of Density | ~10k tokens |
| B | docs/requirements/ + project-context.yaml | Entity Signature Only | ~15k tokens |
| Post-B | project-context.yaml + 出力ファイル参照 | Decision Summary | ~10k tokens |
| Seq | project-context.yaml 全体 | Decision Summary | ~10k tokens |

## Gate 判定フロー

```
reviewer → SendMessage(lead, Gate YAML)

Gate YAML:
  overall: PASS | ROLLBACK_P1 | ROLLBACK_P0
  p0_count: 0
  p1_count: 0
  p2_count: 0
  rollback_targets: []
  p2_items: []

PASS (P0=0, P1≤1):
  → Lead → shutdown_request(全 teammate)
  → Lead → Teammate.cleanup()
  → Lead → ユーザーに完了報告

ROLLBACK_P1 (P0=0, P1≥2):
  → Lead → 影響フェーズの修正タスクを TaskCreate
  → Lead → 新 teammate をスポーンして修正
  → Lead → Aggregator に再統合依頼
  → Lead → 後続フェーズを再実行
  → Lead → reviewer を再スポーン（最大3サイクル）

ROLLBACK_P0 (P0≥1):
  → Lead → ユーザーに通知（要件不足）
  → Lead → web-requirements 再実行
  → Lead → Wave A から全再実行
```

## 禁止事項（全ロール共通）

- teammate が project-context.yaml に直接書き込むこと（Aggregator のみ許可）
- teammate が他の teammate の output_dir に書き込むこと
- Lead がファイルを直接編集すること（delegate mode）
- TaskUpdate で自分のタスク以外のステータスを変更すること
