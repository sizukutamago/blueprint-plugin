# design-docs-plugin

Claude Code プラグインとして、日本語開発者向けの **agent-teams ネイティブ** 設計ドキュメントワークフローを提供するリポジトリ。

**v3.0 の主な変更点（agent-teams 全面移行）:**
- agent-teams による真の並列実行（TeammateTool + TaskList DAG）
- project-context.yaml を大幅簡素化（phases/wave_status/contracts を TaskList に移管）
- handoff-envelope.yaml を非推奨化（SendMessage で代替）
- Aggregator teammate による Blackboard 単一ライター原則
- JIT spawn パターン（Wave 間 shutdown でトークン節約）
- スポーンプロンプトテンプレート（`references/spawn-prompts/`）
- チームモード実行プロトコル（`references/team-mode.md`）

**v2.0 の変更点（引き続き有効）:**
- Phase 1-2 を `web-requirements` スキル（外部プラグイン）で置換
- Wave A/B 並列実行で処理時間を短縮
- P0/P1/P2 Gate 判定による差し戻しロジック

## プロジェクト構造

```
design-docs-plugin/
├── .claude-plugin/          # プラグインメタデータ
├── agents/                  # エージェント定義（6種）
├── commands/                # コマンド定義（1種）
├── skills/                  # スキル実装
│   ├── architecture/        # Phase 3: アーキテクチャ（旧、互換用）
│   ├── architecture-skeleton/ # Phase 3a: Arch Skeleton (Wave A)
│   ├── architecture-detail/   # Phase 3b: Arch Detail (post-B)
│   ├── database/            # Phase 4: データ構造 (Wave A)
│   ├── api/                 # Phase 5: API仕様 (Wave B)
│   ├── design/              # Phase 6: 画面設計（旧、互換用）
│   ├── design-inventory/    # Phase 6a: 画面棚卸し (Wave A)
│   ├── design-detail/       # Phase 6b: 画面詳細 (post-B)
│   ├── implementation/      # Phase 7: 実装準備
│   ├── design-doc-reviewer/ # Phase 8: レビュー (Gate判定)
│   ├── design-doc-orchestrator/ # 全フェーズオーケストレーション（agent-teams 対応）
│   │   └── references/
│   │       ├── team-mode.md       # チームモード実行プロトコル
│   │       └── spawn-prompts/     # 9 teammate スポーンプロンプト
│   ├── wave-aggregator/     # Wave 統合・Blackboard 更新
│   ├── context-compressor/  # コンテキスト圧縮
│   ├── gap-analysis/        # 既存システム分析
│   ├── research/            # 技術調査
│   └── shared/              # 共有テンプレート
│       └── references/
│           ├── project-context.yaml  # Blackboard（簡素化、Aggregator のみ書き込み）
│           └── handoff-envelope.yaml # 非推奨（SendMessage で代替）
├── plans/                   # 計画ファイル
└── docs/                    # マイグレーションガイド等
```

## 外部依存

| プラグイン | スキル | 用途 |
|-----------|--------|------|
| dev-tools-plugin | web-requirements | Phase 1-2 要件定義 |

## コーディング規約

### 言語ポリシー

- **frontmatter description**: 英語（Claude のトリガー検出用）
- **本文**: 日本語（開発者向け）
- **コード例**: コンテキストに応じて混在可

### ファイル構造

**スキル（SKILL.md）:**

```markdown
---
name: skill-name
description: English description for Claude's trigger detection
version: X.Y.Z
---

# スキル名（日本語）

## 前提条件
## 出力ファイル
## 依存関係
## ワークフロー
## ツール使用ルール
## エラーハンドリング
```

**エージェント:**

```markdown
---
name: agent-name
description: English trigger description
model: inherit
color: blue
tools: [list]
---

## Core Responsibilities
## Process Description
## Output Format
```

### ID体系

| プレフィックス | 用途 | 例 |
|---------------|------|-----|
| FR | 機能要件 | FR-001 |
| NFR | 非機能要件 | NFR-PERF-001 |
| SC | 成功基準 | SC-001 |
| API | API仕様 | API-001 |
| ENT | エンティティ | ENT-User |
| ADR | 設計決定記録 | ADR-0001 |

**NFRカテゴリ:**
- PERF: パフォーマンス
- SEC: セキュリティ
- AVL: 可用性
- SCL: スケーラビリティ
- MNT: 保守性
- OPR: 運用
- CMP: 互換性
- ACC: アクセシビリティ

## コマンド

### インストール

```bash
./install.sh                      # ~/.claude にインストール
./install.sh -t /custom/path      # カスタムパス指定
```

### スキル呼び出し

```bash
# 全フェーズ実行（推奨、agent-teams モード）
/design-docs      # agent-teams による 2-wave 並列実行

# 個別フェーズ（上級者向け）
/architecture     # Phase 3: アーキテクチャ設計
/database         # Phase 4: データ構造設計
/api              # Phase 5: API仕様作成
/design           # Phase 6: 画面設計
/implementation   # Phase 7: 実装準備
/review           # Phase 8: レビュー（Gate判定）

# 非推奨（web-requirements に置換）
# /hearing        # → web-requirements を使用
# /requirements   # → web-requirements を使用
```

## agent-teams アーキテクチャ（v3.0）

### 3 概念アーキテクチャ

| 概念 | 用途 |
|------|------|
| `docs/` | 成果物ファイル（各 teammate が書き込み） |
| `TaskList` | 実行 DAG（blockedBy で依存関係管理） |
| `SendMessage` | イベント（contract_outputs YAML で構造化ハンドオフ） |

### チーム構成

```
Lead Agent（delegate mode）
├─ aggregator（常駐）→ project-context.yaml の唯一の書き込み者
├─ Wave A: arch-skeleton, database, design-inventory（並列）
├─ Wave B: api, arch-detail（並列）
├─ Post-B: design-detail
├─ Seq: implementation
└─ Seq: reviewer → Gate 判定
```

### 単一ライター原則

project-context.yaml への書き込みは **Aggregator のみ**。
各 teammate は `contract_outputs` を SendMessage で Lead に送信し、
Lead が Aggregator に転送して統合する。

### 参照ファイル

| ファイル | 説明 |
|---------|------|
| `skills/design-doc-orchestrator/references/team-mode.md` | 実行プロトコル詳細 |
| `skills/design-doc-orchestrator/references/spawn-prompts/` | 9 teammate のプロンプト |
| `skills/shared/references/project-context.yaml` | 簡素化 Blackboard スキーマ |

## 出力規約

設計ドキュメントは `docs/` 配下に生成:

```
docs/
├── project-context.yaml    # Blackboard（decisions + traceability、Aggregator のみ書き込み）
├── 00_analysis/           # 既存システム分析（brownfield）
├── requirements/          # ← 新: web-requirements 出力
│   ├── user-stories.md    # Gherkin 形式
│   ├── context_unified.md # プロジェクトコンテキスト
│   └── story_map.md       # Epic/Feature/Story 階層
├── 03_architecture/       # アーキテクチャ設計
├── 04_data_structure/     # データ構造定義
├── 05_api_design/         # API仕様書
├── 06_screen_design/      # 画面設計書
├── 07_implementation/     # 実装計画
└── 08_review/             # レビュー結果

# 非推奨（旧形式）
# 01_hearing/              # → requirements/ に移行
# 02_requirements/         # → requirements/ に移行
```

## 変更時の注意

### スキル編集時

1. `SKILL.md` の frontmatter description は英語で記述
2. バージョン番号を適切に更新（セマンティックバージョニング）
3. `references/` 配下のテンプレートとの整合性を確認
4. 依存する他スキルへの影響を考慮

### エージェント編集時

1. `tools` リストは実際に使用可能なツールのみ記載
2. `color` は他エージェントと重複しないよう設定
3. `model: inherit` を基本とし、特別な理由がある場合のみ変更

### テンプレート編集時

1. プレースホルダーは `{{placeholder}}` 形式
2. 日本語コメントで用途を明記
3. 実際の出力例を `references/` に配置

## 品質基準

- 曖昧な表現（「など」「適切に」）は具体化するか補足説明を追加
- 用語は `glossary.md` で定義し一貫性を保つ
- 各フェーズの依存関係を明確に定義

## 技術スタック

- **コア**: Claude Code プラグインシステム
- **並列実行**: Claude Code agent-teams（`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`）
- **ドキュメント参照**: Context7 MCP
