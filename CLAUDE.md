# blueprint-plugin

日本語開発者向けの **クロスプラットフォーム対応** 設計ドキュメントワークフロープラグイン。
**Claude Code** と **Cursor** の両方で動作する。

## v4.0 の主な変更点（クロスプラットフォーム対応）

- **core/ 分離**: 全フェーズの仕様を platform 非依存の `core/` に抽出（Single Source of Truth）
- **Contract YAML**: 各フェーズ仕様に機械可読な `## Contract (YAML)` セクション追加
- **Cursor .mdc 対応**: `.cursor/rules/` に 12 ルールファイル（10 phase + orchestrator + always）
- **SKILL.md 薄ラッパー化**: 既存 SKILL.md を core 参照 + Claude Code 固有部分のみに削減（-74%）
- **仕様依存 vs 実行依存の分離**: `core/phases/` に仕様依存、`core/dag.md` に実行依存
- **Blackboard schema v4.0**: platform 非依存スキーマ（書き込みルールを platform 層に委譲）

**v3.2 の変更点（引き続き有効）:**
- 技術スタックユーザー承認ステップ、`approved_tech_stack` フィールド
- Reviewer Level 2 に技術スタック整合性チェック追加

**v3.0-3.1 の変更点（引き続き有効）:**
- agent-teams による並列実行（Claude Code 固有）
- IPA 標準準拠、NFR 測定可能性、Wave C 並列化

## プロジェクト構造

```
blueprint-plugin/
├── core/                        # ★ 統一仕様層（Platform 非依存、Single Source of Truth）
│   ├── phases/                  #   各フェーズの仕様（Contract YAML 付き）
│   │   ├── architecture-skeleton.md
│   │   ├── database.md
│   │   ├── design-inventory.md
│   │   ├── api.md
│   │   ├── architecture-detail.md
│   │   ├── design-detail.md
│   │   ├── impl-standards.md
│   │   ├── impl-test.md
│   │   ├── impl-ops.md
│   │   └── review.md
│   ├── blackboard-schema.yaml   #   project-context.yaml スキーマ
│   ├── dag.md                   #   Wave 構成と依存関係
│   ├── id-system.md             #   ID 採番規約
│   ├── review-criteria.md       #   5段階レビュー + Gate 判定
│   ├── output-structure.md      #   docs/ ディレクトリ構造
│   └── traceability.md          #   トレーサビリティルール
│
├── .cursor/rules/               # ★ Cursor 用ラッパー（.mdc ルール）
│   ├── blueprint-always.mdc     #   共通規約（alwaysApply: true）
│   ├── blueprint-orchestrator.mdc #  全体制御（Agent-Requested）
│   └── phase-*.mdc              #   各フェーズ（Auto-Attach via globs）
│
├── .claude-plugin/              # Claude Code プラグインメタデータ
├── agents/                      # Claude Code エージェント定義（6種）
├── commands/                    # Claude Code コマンド定義（1種）
├── skills/                      # ★ Claude Code 用ラッパー（core 参照 + 固有部分）
│   ├── architecture-skeleton/   #   Phase 3a: core_ref + SendMessage
│   ├── database/                #   Phase 4: core_ref + SendMessage
│   ├── design-inventory/        #   Phase 6a: core_ref + SendMessage
│   ├── api/                     #   Phase 5: core_ref + SendMessage
│   ├── architecture-detail/     #   Phase 3b: core_ref + SendMessage
│   ├── design-detail/           #   Phase 6b: core_ref + SendMessage
│   ├── implementation/          #   Phase 7a: core_ref + SendMessage
│   ├── impl-test/               #   Phase 7b: core_ref + SendMessage
│   ├── impl-ops/                #   Phase 7c: core_ref + SendMessage
│   ├── design-doc-reviewer/     #   Phase 8: core_ref + Gate SendMessage
│   ├── design-doc-orchestrator/ #   オーケストレーション（agent-teams 固有）
│   │   └── references/
│   │       ├── team-mode.md
│   │       └── spawn-prompts/
│   ├── wave-aggregator/         #   Wave 統合（Claude Code 固有）
│   ├── context-compressor/      #   コンテキスト圧縮
│   ├── gap-analysis/            #   既存システム分析
│   ├── research/                #   技術調査
│   ├── architecture/            #   旧、互換用
│   ├── design/                  #   旧、互換用
│   └── shared/references/
│       └── project-context.yaml #   旧 Blackboard（core/ に移管済み）
├── plans/
└── docs/
```

## 三層アーキテクチャ

```
┌─────────────────────────────────────────┐
│  core/  — 統一仕様層（保守の中心）       │
│  phases/*.md + 共通ドキュメント          │
│  Platform 非依存、変更頻度: 高           │
└────────────┬───────────────┬────────────┘
             │               │
   ┌─────────▼──────┐ ┌─────▼──────────┐
   │ skills/SKILL.md │ │ .cursor/rules/ │
   │ Claude Code 用  │ │ Cursor 用      │
   │ 薄いラッパー    │ │ 薄いラッパー   │
   │ 変更頻度: 低    │ │ 変更頻度: 低   │
   └────────────────┘ └────────────────┘
```

**仕様変更時**: `core/` のみ変更 → 両 platform に自動反映
**Claude Code API 変更時**: `skills/*/SKILL.md` のみ変更
**Cursor 仕様変更時**: `.cursor/rules/*.mdc` のみ変更

## 外部依存

| プラグイン | スキル | 用途 |
|-----------|--------|------|
| dev-tools-plugin | web-requirements | Phase 1-2 要件定義 |

## コーディング規約

### 言語ポリシー

- **frontmatter description**: 英語（Claude/Cursor のトリガー検出用）
- **本文**: 日本語（開発者向け）
- **コード例**: コンテキストに応じて混在可

### ファイル構造

**core/phases/*.md（仕様本体）:**

```markdown
# Phase: [フェーズ名]

[概要]

## Contract (YAML)
 ```yaml
phase_id: "X"
required_artifacts: [...]
outputs: [...]
contract_outputs: [...]
quality_gates: [...]
 ```

## 入力要件
## 出力ファイル
## ワークフロー（platform 非依存）
## 仕様詳細
## エラーハンドリング（platform 中立）
```

**skills/*/SKILL.md（Claude Code ラッパー）:**

```markdown
---
name: skill-name
description: English description
version: 2.0.0
core_ref: core/phases/xxx.md
---
# スキル名 (Claude Code)
## 仕様参照（core を参照）
## Claude Code 固有: 実行コンテキスト
## Claude Code 固有: SendMessage 完了報告
```

**.cursor/rules/phase-*.mdc（Cursor ラッパー）:**

```yaml
---
description: "Blueprint - [phase]. Apply when [context]."
globs: "[output_dir]/**,docs/requirements/**,workflow-state/task_plan.md"
alwaysApply: false
---
# [Phase] (Cursor)
## 仕様参照（@core/phases/*.md を読み込み指示）
## Cursor 固有の実行手順
## 状態管理（task_plan.md）
```

### ID体系

詳細は `core/id-system.md` を参照。

| プレフィックス | 用途 | 例 |
|---------------|------|-----|
| FR | 機能要件 | FR-001 |
| NFR | 非機能要件 | NFR-PERF-001 |
| SC | 画面 | SC-001 |
| API | API仕様 | API-001 |
| ENT | エンティティ | ENT-User |
| ADR | 設計決定記録 | ADR-0001 |

## コマンド

### インストール

```bash
# マーケットプレイス経由
/plugin marketplace add sizukutamago/blueprint-plugin
/plugin install blueprint-plugin@blueprint-plugin

# ローカル開発
claude --plugin-dir /path/to/blueprint-plugin

# アップデート（キャッシュクリア）
./scripts/plugin-update.sh
```

### スキル呼び出し（Claude Code）

```bash
# 全フェーズ実行（推奨、agent-teams モード）
/design-docs      # agent-teams による 3-wave 並列実行

# 個別フェーズ（上級者向け）
/architecture-skeleton  # Phase 3a
/database               # Phase 4
/api                    # Phase 5
/design                 # Phase 6
/implementation         # Phase 7
/review                 # Phase 8: Gate判定
```

### Cursor での使用

1. プロジェクトルートに `.cursor/rules/` が自動適用される
2. 「設計ドキュメントを作成して」等のプロンプトで `blueprint-orchestrator.mdc` が発火
3. 各フェーズは出力ディレクトリの `globs` パターンで Auto-Attach
4. `workflow-state/task_plan.md` でフェーズ進捗を追跡

## Claude Code: agent-teams アーキテクチャ

### チーム構成

```
Lead Agent（delegate mode）
├─ aggregator（常駐）→ project-context.yaml の唯一の書き込み者
├─ Wave A: arch-skeleton, database, design-inventory（並列）
├─ Wave B: api, arch-detail（並列）
├─ Post-B: design-detail
├─ Wave C: impl-standards, impl-test, impl-ops（並列）
└─ Seq: reviewer → Gate 判定
```

### 単一ライター原則

- **Claude Code**: Aggregator teammate のみが project-context.yaml に書き込み
- **Cursor**: メインエージェントが各フェーズ完了後に直接更新

## 出力規約

詳細は `core/output-structure.md` を参照。設計ドキュメントは `docs/` 配下に生成。

## 変更時の注意

### core/ 編集時（最も頻繁）

1. `core/phases/*.md` の Contract YAML を正確に維持
2. core に **Claude Code 固有用語を含めない**（SendMessage, agent-teams, spawn, Aggregator 等）
3. ワークフローの最後は「contract_outputs を出力」（transport は書かない）
4. エラーハンドリングは platform 中立（「P0 報告」「入力要請」）

### SKILL.md 編集時（Claude Code API 変更時のみ）

1. frontmatter の `core_ref` が正しい core ファイルを参照していること
2. 仕様は core に委譲し、Claude Code 固有部分のみ残す
3. SendMessage フォーマットの変更は SKILL.md 側で対応

### .cursor/rules/*.mdc 編集時（Cursor 仕様変更時のみ）

1. `@core/phases/*.md` の参照パスが正しいこと
2. `globs` パターンが出力ディレクトリ + 入力ディレクトリをカバー
3. `workflow-state/task_plan.md` への読み書き指示を含む

## 品質基準

- 曖昧な表現（「など」「適切に」）は具体化するか補足説明を追加
- 用語は `glossary.md` で定義し一貫性を保つ
- 各フェーズの依存関係は `core/dag.md` で明確に定義

## 技術スタック

- **コア**: Claude Code プラグインシステム + Cursor Rules (.mdc)
- **並列実行**: Claude Code agent-teams / Cursor 2.0 並列 Agent
- **ドキュメント参照**: Context7 MCP
- **仕様管理**: core/ (Single Source of Truth)
