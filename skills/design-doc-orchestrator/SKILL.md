---
name: design-doc-orchestrator
description: This skill should be used when the user asks to "create design documents", "generate full documentation", "run design workflow", "orchestrate design phases", or "create complete system specifications". Orchestrates comprehensive system design documentation through agent-teams 2-wave parallel execution with TaskList DAG coordination.
version: 3.0.0
---

# Design Doc Orchestrator

システム設計書一式を agent-teams で生成するオーケストレータ。
**2-wave 並列実行**で効率的に設計書を作成する。

**前提条件**: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` が設定済みであること。

## チーム構成

```
Lead Agent（オーケストレータ、delegate mode）
│
├─ aggregator (常駐) → project-context.yaml の唯一の書き込み者
│
├─ Wave A（3 teammate 並列）
│  ├─ arch-skeleton   (opus)   → 03_architecture/{architecture,adr}.md
│  ├─ database        (sonnet) → 04_data_structure/
│  └─ design-inventory(sonnet) → 06_screen_design/{screen_list,screen_transition}.md
│
├─ Wave B（2 teammate 並列）
│  ├─ api             (sonnet) → 05_api_design/
│  └─ arch-detail     (sonnet) → 03_architecture/{security,infrastructure,cache_strategy}.md
│
├─ Post-B
│  └─ design-detail   (sonnet) → 06_screen_design/{component_catalog,details/}
│
├─ Sequential
│  └─ implementation  (sonnet) → 07_implementation/
│
└─ Sequential
   └─ reviewer        (opus)   → 08_review/
```

### 役割分担

| 役割 | 責務 | ファイル編集 |
|------|------|------------|
| Lead | Gate 判定、ユーザー確認、Wave 遷移制御、チーム管理 | 不可（delegate mode） |
| Aggregator | Blackboard 更新、矛盾検出、コンテキスト圧縮 | project-context.yaml のみ |
| 各 teammate | スキル実行、成果物ファイル書き込み | 自分の output_dir のみ |

## Wave 構成

### Wave A（並列）
- **architecture-skeleton**: 技術選定、システム境界、NFR方針
- **database**: エンティティ定義
- **design-inventory**: 画面一覧、遷移図

### Wave B（並列、Wave A Aggregator 完了後）
- **api**: API 設計（ENT 依存）
- **architecture-detail**: セキュリティ、インフラ、キャッシュ（方針依存）

### Post-B（Wave B Aggregator 完了後）
- **design-detail**: 画面詳細（API 依存）

## ワークフロー

```
[開始] モード判定（greenfield/brownfield）
    ↓
┌─────────────────────────────────────────────┐
│ [Phase 1-2] web-requirements スキル呼び出し   │
│ 出力: docs/requirements/{user-stories.md, ...} │
└─────────────────────────────────────────────┘
    ↓ ★ユーザー承認待ち

Lead → Teammate.spawnTeam("design-docs")
Lead → Task(aggregator)  ← 常駐スポーン
Lead → TaskCreate × 11   ← DAG 作成

┌──────────────Wave A（並列）──────────────┐
│                │                         │
↓                ↓                         ↓
[3a] Arch      [4] Database           [6a] Design
Skeleton       (sonnet)               Inventory
(opus)                                (sonnet)
    │                │                     │
    └────────────────┼─────────────────────┘
                     ↓
           [Aggregator] Wave A 統合
           → project-context.yaml 更新
           → Wave A teammate shutdown
                     ↓
         ┌─────Wave B（並列）─────┐
         │                       │
         ↓                       ↓
    [5] API                 [3b] Arch Detail
    (sonnet)                (sonnet)
         │                       │
         └───────────┬───────────┘
                     ↓
           [Aggregator] Wave B 統合
           → project-context.yaml 更新
           → Wave B teammate shutdown
                     ↓
    [6b] Design Detail (sonnet)
                     ↓
    [Phase 7] Implementation (sonnet)
                     ↓
    [Phase 8] Review (opus)
                     ↓
           Gate 判定
           ├─ PASS → cleanup → 完了
           ├─ P1 → 該当フェーズ修正 → 再レビュー
           └─ P0 → ユーザー通知 → web-requirements 再実行
```

## TaskList DAG

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

## Blackboard 連携（単一ライター原則）

### 書き込みフロー

```
teammate → ファイル書き込み(自分の output_dir)
teammate → SendMessage(lead, contract_outputs YAML)
lead     → SendMessage(aggregator, "統合依頼" + contract_outputs 転送)
aggregator → project-context.yaml 更新(Two-step Reduce)
aggregator → SendMessage(lead, "統合完了/矛盾検出")
```

### コンテキスト渡し

| Wave | ソース | 圧縮戦略 | 目標 |
|------|--------|----------|------|
| A | docs/requirements/ | Chain of Density | ~10k tokens |
| B | docs/requirements/ + project-context.yaml | Entity Signature Only | ~15k tokens |
| Post-B | project-context.yaml + 出力ファイル参照 | Decision Summary | ~10k tokens |
| Seq | project-context.yaml 全体 | Decision Summary | ~10k tokens |

## Gate 判定と差し戻しロジック

| 判定 | 条件 | アクション |
|------|------|-----------|
| PASS | P0=0, P1≤1 | cleanup → 完了 |
| ROLLBACK_P1 | P0=0, P1≥2 | 該当フェーズ修正 → Aggregator 再統合 → 再レビュー |
| ROLLBACK_P0 | P0≥1 | ユーザー通知 → web-requirements 再実行 → 全再実行 |

### 差し戻し時の動作

```
P1 検出:
  → reviewer の rollback_targets から影響フェーズを特定
  → TaskCreate で修正タスクを作成
  → 新 teammate をスポーンして修正実行
  → Aggregator に再統合依頼
  → 後続フェーズを再実行
  → reviewer を再スポーン（最大3サイクル）

P0 検出:
  → ユーザーに通知（要件不足）
  → web-requirements を再実行
  → Wave A から全再実行
  → （最大3サイクル、超過時はユーザー介入要請）
```

## ユースケース別フロー

### 新規プロジェクト（greenfield）

```
web-requirements → Wave A → Agg A → Wave B → Agg B → Post-B → impl → review
```

### 既存プロジェクト機能追加（brownfield）

```
research → gap-analysis → web-requirements(差分) → (影響範囲のみ) → review
```

## スポーンプロンプト

各 teammate のスポーンプロンプトテンプレートは `references/spawn-prompts/` に配置:

| ファイル | teammate |
|---------|----------|
| `aggregator.md` | Aggregator（常駐） |
| `wave-a-arch-skeleton.md` | Architecture Skeleton |
| `wave-a-database.md` | Database |
| `wave-a-design-inventory.md` | Design Inventory |
| `wave-b-api.md` | API |
| `wave-b-arch-detail.md` | Architecture Detail |
| `post-b-design-detail.md` | Design Detail |
| `seq-implementation.md` | Implementation |
| `seq-reviewer.md` | Reviewer |

詳細な実行プロトコルは `references/team-mode.md` を参照。

## 出力ディレクトリ構造

```
docs/
├── 00_analysis/           # オプション（brownfield）
├── requirements/           # web-requirements 出力
│   ├── user-stories.md
│   ├── context_unified.md
│   └── story_map.md
├── 03_architecture/
│   ├── architecture.md    # Wave A: skeleton
│   ├── adr.md             # Wave A: skeleton
│   ├── security.md        # Wave B: detail
│   ├── infrastructure.md  # Wave B: detail
│   └── cache_strategy.md  # Wave B: detail
├── 04_data_structure/     # Wave A
│   └── data_structure.md
├── 05_api_design/         # Wave B
│   ├── api_design.md
│   └── integration.md
├── 06_screen_design/
│   ├── screen_list.md     # Wave A: inventory
│   ├── screen_transition.md # Wave A: inventory
│   ├── component_catalog.md # Post-B: detail
│   ├── error_patterns.md    # Post-B: detail
│   ├── ui_testing_strategy.md # Post-B: detail
│   └── details/             # Post-B: detail
│       └── screen_detail_SC-XXX.md
├── 07_implementation/
│   ├── coding_standards.md
│   ├── environment.md
│   ├── testing.md
│   └── operations.md
├── 08_review/
│   ├── consistency_check.md
│   └── project_completion.md
└── project-context.yaml   # Blackboard（Aggregator が管理）
```

## ID体系

| ID | 形式 | 担当 teammate |
|----|------|-------------|
| FR | FR-XXX | web-requirements |
| NFR | NFR-[CAT]-XXX | web-requirements |
| SC | SC-XXX | design-inventory |
| API | API-XXX | api |
| ENT | ENT-{Name} | database |
| ADR | ADR-XXXX | arch-skeleton / arch-detail |

## ユーザー確認ポイント

### 必須（Phase 2 完了後）

要件定義の承認が必要。承認されるまで Wave A に進まない。

### Gate 判定後（P0 時）

要件不足が検出された場合、ユーザーに通知して web-requirements 再実行の承認を得る。

## エラーハンドリング

| エラー種別 | 対応 |
|-----------|------|
| teammate スポーン失敗 | リトライ（最大3回）、失敗時ユーザーに報告 |
| SendMessage パース失敗 | Lead がエラーを検出し teammate に再送依頼 |
| Aggregator 矛盾検出 | P1 として該当フェーズへ差し戻し |
| Gate ロールバック3回超過 | ユーザー介入要請 |

## リトライポリシー

```
エラー発生
    ↓
エラー内容をユーザーに報告
    ↓
ユーザー選択: [リトライ] / [スキップ] / [中断]
    ↓
リトライ: 最大3回まで
スキップ: 次フェーズへ（警告を記録）
中断: 現状を保存して終了
```
