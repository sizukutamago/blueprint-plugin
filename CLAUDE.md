# blueprint-plugin

日本語開発者向けの **クロスプラットフォーム対応** Contract-first 設計ワークフロープラグイン。
**Claude Code** と **Cursor** の両方で動作する。

## 概要

- **ワークフロー**: `/spec` → `/test-from-contract` → 実装 → `/generate-docs`
- **`.blueprint/` ディレクトリ**: contracts/ (I/O 境界仕様) + concepts/ + decisions/
- **Contract YAML**: 3 タイプ (api/external/file) の機械可読 I/O 境界仕様
- **Review Swarm**: 各ステージ完了時に 3 エージェント並列レビュー（P0/P1/P2 Gate 判定）
- **設計書はコードから後追い生成**: `/generate-docs` でコード → docs/

## プロジェクト構造

```
blueprint-plugin/
├── core/                        # ★ 統一仕様層（Platform 非依存、Single Source of Truth）
│   ├── spec.md                  #   /spec ワークフロー
│   ├── test-from-contract.md    #   /test-from-contract ワークフロー
│   ├── generate-docs.md         #   /generate-docs ワークフロー
│   ├── orchestrator.md          #   /blueprint オーケストレーター
│   ├── contract-schema.md       #   Contract YAML スキーマ（3 types）
│   ├── blueprint-structure.md   #   .blueprint/ 構造 + ID 体系
│   ├── output-structure.md      #   docs/ 出力構造
│   ├── doc-format-standards.md  #   設計書フォーマット基準
│   ├── id-system.md             #   ID 採番規約
│   ├── review-criteria.md       #   5段階レビュー + Gate 判定
│   └── traceability.md          #   トレーサビリティルール
│
├── .cursor/rules/               # ★ Cursor 用ラッパー（.mdc ルール）
│   ├── blueprint-always.mdc     #   共通規約（alwaysApply: true）
│   ├── blueprint-orchestrator.mdc #  パイプライン全体制御
│   ├── blueprint-spec.mdc       #   /spec ワークフロー
│   ├── blueprint-generate-docs.mdc # /generate-docs ワークフロー
│   └── blueprint-test-from-contract.mdc # /test-from-contract ワークフロー
│
├── .claude-plugin/              # Claude Code プラグインメタデータ
├── commands/                    # Claude Code コマンド定義
│   ├── blueprint.md             #   /blueprint（パイプライン全体）
│   ├── spec.md                  #   /spec
│   ├── test-from-contract.md    #   /test-from-contract
│   └── generate-docs.md         #   /generate-docs
├── skills/                      # ★ Claude Code 用ラッパー（core 参照 + 固有部分）
│   ├── orchestrator/            #   パイプラインオーケストレーター
│   │   └── references/
│   │       └── review-prompts/  #   Review Swarm プロンプト（4 gates）
│   ├── spec/                    #   ブレスト + Contract 生成
│   ├── generate-docs/           #   コードから設計書生成
│   ├── test-from-contract/      #   Contract から TDD テスト生成
│   ├── gap-analysis/            #   既存システム分析
│   ├── research/                #   技術調査
│   ├── context-compressor/      #   コンテキスト圧縮
│   └── shared/references/       #   テンプレート例
├── plans/
└── docs/
```

## 三層アーキテクチャ

```
┌─────────────────────────────────────────┐
│  core/  — 統一仕様層（保守の中心）       │
│  ワークフロー定義 + 共通ドキュメント     │
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

## コーディング規約

### 言語ポリシー

- **frontmatter description**: 英語（Claude/Cursor のトリガー検出用）
- **本文**: 日本語（開発者向け）
- **コード例**: コンテキストに応じて混在可

### ファイル構造

**core/*.md（仕様本体）:**

```markdown
# [ワークフロー名]

[概要]

## ワークフロー（platform 非依存）
## 仕様詳細
## エラーハンドリング（platform 中立）
```

**skills/*/SKILL.md（Claude Code ラッパー）:**

```markdown
---
name: skill-name
description: English description
version: 1.0.0
core_ref: core/xxx.md
---
# スキル名 (Claude Code)
## 仕様参照（core を参照）
## Claude Code 固有: 実行コンテキスト
```

**.cursor/rules/*.mdc（Cursor ラッパー）:**

```yaml
---
description: "Blueprint - [workflow]. Apply when [context]."
globs: "[relevant_dirs]/**"
alwaysApply: false
---
# [Workflow] (Cursor)
## 仕様参照（@core/*.md を読み込み指示）
## Cursor 固有の実行手順
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
| CON | Contract | CON-xxx |
| CONCEPT | 概念ノード | CONCEPT-xxx |
| DEC | 決定ログ | DEC-xxx |

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
/blueprint              # 全パイプライン自動実行（/spec → テスト → docs）
/blueprint --resume     # 実装後に Stage 4 から再開
/blueprint --force      # 全ステージ強制再実行
/spec                   # ブレスト → Contract YAML 生成
/test-from-contract     # Contract から TDD テスト生成
/generate-docs          # コードから設計書を後追い生成
```

### Cursor での使用

1. プロジェクトルートに `.cursor/rules/` が自動適用される
2. 「設計ドキュメントを作成して」等のプロンプトで `blueprint-orchestrator.mdc` が発火
3. 各ワークフローは出力ディレクトリの `globs` パターンで Auto-Attach

## 出力規約

詳細は `core/output-structure.md` を参照。設計ドキュメントは `docs/` 配下に生成。

## 変更時の注意

### core/ 編集時（最も頻繁）

1. core に **Claude Code 固有用語を含めない**（Task spawn 等の実行詳細）
2. ワークフローの最後は「出力を生成」（transport は書かない）
3. エラーハンドリングは platform 中立（「P0 報告」「入力要請」）

### SKILL.md 編集時（Claude Code API 変更時のみ）

1. frontmatter の `core_ref` が正しい core ファイルを参照していること
2. 仕様は core に委譲し、Claude Code 固有部分のみ残す

### .cursor/rules/*.mdc 編集時（Cursor 仕様変更時のみ）

1. `@core/*.md` の参照パスが正しいこと
2. `globs` パターンが出力ディレクトリ + 入力ディレクトリをカバー

## 品質基準

- 曖昧な表現（「など」「適切に」）は具体化するか補足説明を追加
- 用語は `glossary.md` で定義し一貫性を保つ

## 技術スタック

- **コア**: Claude Code プラグインシステム + Cursor Rules (.mdc)
- **ドキュメント参照**: Context7 MCP
- **仕様管理**: core/ (Single Source of Truth)
