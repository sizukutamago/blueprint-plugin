---
name: generate-docs
description: Generate design documents from existing code. Use when the user wants to "generate design docs", "create documentation from code", "reverse engineer architecture", "extract design documents", "document existing system", "create docs from implementation", "generate screen design docs", "document UI components", or "create frontend design specs". Also use when the user says "設計書を生成する", "ドキュメントを作る", "コードから仕様書を作成", "画面設計書を生成", or "アーキテクチャドキュメントを書く". Analyzes source code and generates design documentation.
version: 1.0.0
core_ref: core/generate-docs.md
---

# Generate Docs スキル (Claude Code)

実装済みコードから設計書を `docs/` 配下に後追い生成するスキル。
コードの事実を記録し、不明な点は TODO として残すか、ユーザーに確認する。

## 仕様参照

本スキルのワークフローは `core/generate-docs.md` に定義。
出力構造は `core/output-structure.md` を参照。
各設計書のフォーマットは `core/doc-format-standards.md` を参照。
抽出ルールは `{baseDir}/references/extraction-rules.md` を参照。

## 前提条件

| 条件 | 必須 | 説明 |
|------|------|------|
| ソースコード | ○ | 分析対象のプロジェクト |
| Git リポジトリ | ○ | docs/ をプロジェクトルートに配置 |
| .blueprint/ | △ | あればトレーサビリティ検証可能。なくても動作する |

## 出力ファイル

| ディレクトリ | ファイル数 | 説明 |
|------------|----------|------|
| `docs/03_architecture/` | 5 | アーキテクチャ設計 |
| `docs/04_data_structure/` | 1 | データ構造 |
| `docs/05_api_design/` | 2 | API 設計 |
| `docs/06_screen_design/` | 5+ | 画面設計（フロントエンドがある場合） |
| `docs/07_implementation/` | 8-10 | 実装準備 |
| `docs/08_review/` | 2 | レビュー結果 |

## ツール

| ツール | 用途 |
|--------|------|
| Bash | git root 検出、tree 構造取得、tech stack 検出 |
| Glob | ソースコード・設定ファイルの一覧取得 |
| Grep | パターン検索（ルート定義、モデル定義、import 等） |
| Read | ソースコード・設定ファイルの内容分析 |
| Write | 設計書ファイルの書き出し |

## ワークフロー（Claude Code 固有部分）

`core/generate-docs.md` の 5 ステップに従う。以下は Claude Code 固有の実行詳細:

### Step 1: プロジェクト分析

```bash
# git root を検出
git rev-parse --show-toplevel

# ディレクトリ構造を取得
tree -L 3 -I 'node_modules|.git|dist|build' --dirsfirst
```

```
# tech stack 検出
Read("package.json")  # or go.mod, Cargo.toml, etc.
Glob("**/tsconfig.json")
Glob("**/Dockerfile")
Glob("**/docker-compose*.yml")
```

```
# .blueprint/ スキャン（存在する場合）
Glob(".blueprint/**/*.yaml")
Glob(".blueprint/**/*.md")
```

### Step 2: 自動抽出フェーズ

抽出ルール（`{baseDir}/references/extraction-rules.md`）に従って実行。

グループ A（直接抽出可能）を先に、次にグループ B を実行。

各ファイル生成後に確信度を `<!-- confidence: high/medium/low -->` で付与。

### Step 3: 補足入力フェーズ

フロントエンドがある場合のみ画面系の質問を行う。

```
質問例:
「以下のコンポーネントが見つかりました。これらの画面名と用途を教えてください:
1. src/pages/Home.tsx → ?
2. src/pages/OrderList.tsx → ?
3. ...」
```

### Step 5: レビュー + サマリー

```
サマリー出力:
## 生成結果
- 生成ファイル: {N} ファイル
- 確信度: high {X}, medium {Y}, low {Z}
- TODO 残: {N} 箇所

## 不整合
- {あれば列挙}

## 次のステップ
- TODO の解消: low 確信度セクションの情報補完
- `/spec` でまだ定義していない I/O 境界があれば Contract を追加
```

## 原則

| 原則 | 説明 |
|------|------|
| 事実記録 | コードにない情報は推測しない。TODO にする |
| 確信度明示 | 各セクションに high/medium/low を付与 |
| 標準出力 | docs/ 構造・フォーマットは doc-format-standards.md 準拠 |
| 段階的生成 | 1 回で完成しなくてよい。繰り返し実行で TODO を埋める |

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| ソースコードなし | 対象ディレクトリの確認を促す |
| 未知の tech stack | 汎用抽出ルール適用 + ユーザーに確認 |
| .blueprint/ なし | docs/ 生成は可能、トレーサビリティ検証はスキップ |
| フロントエンドなし | 06_screen_design/ をスキップ |
| 既存 docs/ あり | 上書き前にユーザー確認 |
