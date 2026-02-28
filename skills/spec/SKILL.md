---
name: spec
description: Create I/O boundary contracts through brainstorming. Use when the user wants to "create contract", "define spec", "brainstorm API design", "design I/O boundary", "define external integration", "specify file format", or "start knowledge base". Combines interactive brainstorming with structured contract YAML generation.
version: 1.0.0
core_ref: core/spec.md
---

# Spec スキル (Claude Code)

ブレインストーミングを通じて Contract YAML を生成するスキル。
ユーザーと対話しながらビジネスルールを深掘りし、テスト可能な I/O 境界仕様を作成する。

## 仕様参照

本スキルのワークフローは `core/spec.md` に定義。
Contract YAML のスキーマは `core/contract-schema.md` を参照。
`.blueprint/` の構造規約は `core/blueprint-structure.md` を参照。

## 前提条件

| 条件 | 必須 | 説明 |
|------|------|------|
| Git リポジトリ | ○ | `.blueprint/` をプロジェクトルートに配置するため |
| 対象ドメインの基本知識 | ○ | ユーザーがビジネスルールを判断できること |

## 出力ファイル

| ファイル | 説明 |
|---------|------|
| `.blueprint/config.yaml` | プロジェクト設定（初回のみ） |
| `.blueprint/contracts/{type}/{name}.contract.yaml` | Contract YAML（メイン出力） |
| `.blueprint/concepts/{name}.md` | ドメイン概念メモ（副産物） |
| `.blueprint/decisions/DEC-{NNN}-{name}.md` | 設計判断記録（副産物） |

## ツール

| ツール | 用途 |
|--------|------|
| Bash | git root 検出 (`git rev-parse --show-toplevel`) |
| Glob | `.blueprint/` 配下の既存ファイル一覧取得 |
| Read | 既存 Contract/Concept/Decision の読み込み |
| Write | Contract YAML、Concept、Decision の書き出し |

## ワークフロー（Claude Code 固有部分）

`core/spec.md` の 7 ステップに従う。以下は Claude Code 固有の実行詳細:

### Step 1: コンテキスト読み込み

```bash
# git root を検出
git rev-parse --show-toplevel
```

```
# 既存 .blueprint/ のスキャン
Glob(".blueprint/**/*.yaml")
Glob(".blueprint/**/*.md")
```

`.blueprint/` が存在しない場合は、ディレクトリ構造を初期化:
```
.blueprint/
├── contracts/
│   ├── api/
│   ├── external/
│   └── files/
├── concepts/
└── decisions/
```

### Step 2: スコープ確認 + config.yaml 生成

`core/spec.md` Step 2 に従いスコープを確認。

**config.yaml 生成（初回のみ）**:
`.blueprint/config.yaml` が存在しない場合に実行。

```
# 技術スタック検出
Read("package.json")
Read("tsconfig.json")
Glob("*.lock*")
Glob("biome.json")
Glob(".eslintrc*")
Glob(".github/workflows/*")

# 検出結果をユーザーに提示して確認/修正
# architecture.pattern はユーザーに選択を求める（clean / layered / flat）

# config.yaml を書き出し
Write(".blueprint/config.yaml")
```

### Step 3: ブレインストーミング

対話のコツ:
- 質問は 1 つずつ（まとめて聞かない）
- ユーザーの回答からフォローアップ質問を導出
- 具体的な値（数値範囲、パターン、列挙値）を引き出す
- 「他にエラーケースはありますか？」で網羅性を確認

### Step 5: Contract YAML 生成

テンプレートは `{baseDir}/references/contract-templates/` から読み込む:
- `api.yaml` — 自社 API
- `external.yaml` — 外部 API
- `file.yaml` — ファイル連携

テンプレートの `{{placeholder}}` をブレスト結果で埋める。

**implementation セクション対話（オプション）**:

各 Contract の基本フィールド生成後、`core/spec.md` Step 5 の implementation セクション対話に従い、
data_sources と flow をユーザーと対話して決定する。ユーザーが「スキップ」と回答した場合は省略。

### Step 7: サマリー出力

生成結果をユーザーに提示し、次のアクションを案内:

```
## 生成ファイル
- .blueprint/contracts/api/{name}.contract.yaml (CON-{name} v1.0.0)
- ...

## 次のステップ
テストを生成するには: `/test-from-contract`

## 未解決事項
- {open_questions}
```

## 原則

| 原則 | 説明 |
|------|------|
| 対話優先 | AI は質問者。ユーザーが業務判断する |
| テスト可能性 | 曖昧な表現は具体的な数値・パターン・列挙値に変換する |
| 小さい Contract | 1 Contract = 1 I/O 境界。大きすぎる場合は分割提案 |

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| git root 検出失敗 | ユーザーにプロジェクトルートで実行するよう案内 |
| 既存 Contract との ID 重複 | 既存ファイルを提示し、更新か新規かを確認 |
| ブレストが収束しない | 10 質問上限、未解決事項は open_questions に退避 |
