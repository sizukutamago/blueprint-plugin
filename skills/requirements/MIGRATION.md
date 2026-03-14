# Requirements スキル — 移植メモ（✅ 移植完了: 2026-03-14）

> **ステータス**: 移植完了。以下は移植時の参考資料として残す。

## 背景

`web-requirements` スキルが dev-tools-plugin v3.0.0 に存在したが、v4.5.0 で削除された。
design-doc-orchestrator の Phase 1-2 がこのスキルに依存しているため、blueprint-plugin 側に `requirements` として再構築する。

## 旧スキルの場所

```
/Users/sizukutamago/.claude/plugins/cache/dev-tools-plugin/dev-tools-plugin/3.0.0/skills/web-requirements/
```

## 旧スキル構成

```
web-requirements/
├── SKILL.md                          # メイン定義（6 Phase ワークフロー）
├── README.md
├── references/
│   ├── handoff_schema.md             # エージェント間ハンドオフ封筒スキーマ
│   ├── interview_questions.md        # AskUserQuestion 質問テンプレート（Double Diamond）
│   ├── quality_rules.md              # 品質ルール（曖昧語リスト、P0判定条件）
│   ├── scope_manifest.md             # スコープ分割仕様（150ファイル/20kLOC閾値）
│   └── user_stories_format.md        # ユーザーストーリー出力形式仕様
├── agents/
│   ├── aggregator.md                 # Two-step Reduce（Opus）
│   ├── planner.md                    # ストーリーマップ構造化（Opus）
│   ├── writer.md                     # ユーザーストーリー生成（Sonnet）
│   └── swarm/
│       ├── explorer-tech.md          # 技術スタック分析（Sonnet）
│       ├── explorer-domain.md        # ドメインモデル分析（Opus）
│       ├── explorer-ui.md            # UIコンポーネント分析（Sonnet）
│       ├── explorer-integration.md   # 外部連携分析（Opus）
│       ├── explorer-nfr.md           # 非機能要件分析（Sonnet）
│       ├── reviewer-completeness.md  # 完全性チェック（Haiku）
│       ├── reviewer-consistency.md   # 一貫性チェック（Opus）
│       ├── reviewer-quality.md       # 品質チェック（Haiku）
│       ├── reviewer-testability.md   # テスト可能性チェック（Haiku）
│       └── reviewer-nfr.md           # 非機能要件チェック（Haiku）
├── scripts/
│   ├── estimate_scope.sh             # スコープ推定（ファイル数/LOC計算）
│   ├── hook_router.sh                # 書き込み制限Hook
│   └── validate_user_stories.py      # ユーザーストーリーバリデーション
├── templates/
│   └── docs/requirements/.gitignore
└── assets/
    └── hooks/requirements_hooks.json # Claude Code Hook設定
```

## ワークフロー（6 Phase）

```
Phase 0: モード判定（greenfield/brownfield） + スコープ推定
    ↓
Phase 1: Explorer Swarm（5並列、brownfield のみ。greenfield はスキップ）
    → tech, domain, ui, integration, nfr
    → Aggregator で Two-step Reduce → context_unified.md
    ↓
Phase 2: Interviewer（AskUserQuestion、Double Diamond パターン）
    → 2-4問 × 2-3サイクル = 6-12問が目安
    → ペルソナ、ユースケース、非目標、成功指標、影響範囲
    ↓
Phase 3: Planner（Opus エージェント）
    → Epic → Feature → Story の階層構造
    → 依存関係、MVP スコープ定義
    → story_map.md
    ↓
Phase 4: Writer（Sonnet エージェント）
    → As a / I want / So that 形式
    → Gherkin AC（Given/When/Then）、失敗系AC必須
    → user-stories.md
    ↓
Phase 5: Reviewer Swarm（5並列）
    → completeness, consistency, quality, testability, nfr
    → Aggregator で統合レビュー
    ↓
Phase 6: Gate 判定
    → P0=0 & P1<2 で PASS
    → P0≥1 で veto（即差し戻し）
    → P1≥2 で差し戻し先を決定（Phase 2/3/4）
```

## 最終出力

- `docs/requirements/user-stories.md` — ユーザーストーリー＋Gherkin AC
- `docs/requirements/.work/` — 中間成果物（.gitignore対象）
  - `00_scope_manifest.json`
  - `01_explorer/*.md`
  - `02_context_unified.md`
  - `03_questions.md`
  - `04_story_map.md`
  - `06_reviewer/*.md`
  - `07_review_unified.md`

## ID 体系

| ID | 形式 | 用途 |
|----|------|------|
| P-XXX | ペルソナ | P-001: 忙しい社会人 |
| Epic-XXX | エピック | Epic-001: 献立自動化 |
| US-XXX | ユーザーストーリー | US-001: 週間プラン生成 |
| AC-XXX-Y | 受け入れ基準 | AC-001-1: 正常系 |
| D-XXX | 決定事項 | D-001: AI はモックで開始 |

## design-doc-orchestrator との連携

orchestrator は以下を期待している:
- **入力**: README.md、既存コード（brownfield時）
- **出力**: `docs/requirements/user-stories.md`, `docs/requirements/context_unified.md`, `docs/requirements/story_map.md`
- **orchestrator の DAG**: `task-1: requirements` → Wave A の blockedBy に指定
- **承認フロー**: requirements 完了後にユーザー承認が必須（承認されるまで Wave A に進まない）

orchestrator の spawn-prompts は requirements の出力ファイルを直接参照する:
- Wave A は `docs/requirements/user-stories.md` を入力として受け取る
- Aggregator は requirements の ID 体系を Blackboard に引き継ぐ

## 移植時の変更候補

1. **スキル名**: `web-requirements` → `requirements`（Web に限定しない）
2. **description の trigger**: 「要件定義」「ユーザーストーリー」「define requirements」等を維持
3. **"Web" 固有の記述を汎用化**: モバイルアプリ等も対象にできるよう
4. **orchestrator の参照更新**: `web-requirements` → `requirements` に変更必要
5. **agent-teams 対応**: 旧版は Task ツール前提。現行の agent-teams（TeamCreate/SendMessage）に合わせるか検討
6. **Explorer Swarm のスコープ**: UI explorer が Web 固有（React/Vue/Svelte）なので、モバイル対応が必要なら拡張

## 優先度

P0: SKILL.md + references/（これがないと orchestrator が動かない）
P1: agents/（Swarm パターンの実装）
P2: scripts/（バリデーション・Hook）
