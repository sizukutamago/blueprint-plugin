---
name: spec
description: Create I/O boundary contracts through brainstorming. Use when the user wants to "create contract", "define spec", "brainstorm API design", "design I/O boundary", "define external integration", "specify file format", "design screen", "create UI spec", "define form contract", "screen contract", "design page layout", or "define frontend spec". Also use when the user asks to start a new feature, create .blueprint directory, or brainstorm a new service. Also use when the user says "仕様を作る", "APIを設計する", "コントラクト作成", "画面を設計する", "I/O境界を定義する", "ブレインストーミング", or "新機能の仕様を決める". Combines interactive brainstorming with structured contract YAML generation for all types: api, external, file, internal, and screen.
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
| `.blueprint/contracts/{type}/{name}.contract.yaml` | Contract YAML（メイン出力、type: api/external/file/internal/screen） |
| `.blueprint/concepts/{name}.md` | ドメイン概念メモ（副産物） |
| `.blueprint/decisions/DEC-{NNN}-{name}.md` | 設計判断記録（副産物） |
| `.claude/rules/base.md` | プロジェクト基本規約（初回のみ、常時読み込み） |
| `.claude/rules/typescript.md` | TypeScript 規約（TypeScript プロジェクトのみ） |
| `.claude/rules/react.md` | React 規約（React/Next.js プロジェクトのみ） |
| `.claude/rules/testing-library.md` | テスト規約（@testing-library プロジェクトのみ） |

## ツール

| ツール | 用途 |
|--------|------|
| Bash | git root 検出 (`git rev-parse --show-toplevel`) |
| Glob | `.blueprint/` 配下の既存ファイル一覧取得 |
| Read | 既存 Contract/Concept/Decision の読み込み |
| Write | Contract YAML、Concept、Decision の書き出し |

## ワークフロー（Claude Code 固有部分）

`core/spec.md` の 7 ステップに従う。以下は Claude Code 固有の実行詳細:

### Step 1: コンテキスト読み込み + config.yaml 生成（必須）

**⛔ 絶対必須: ブレインストーミング開始前に config.yaml を確認・生成すること。この Step を省略してはならない。**

```bash
# git root を検出
git rev-parse --show-toplevel
```

実行順序:

1. `Glob(".blueprint/config.yaml")` で存在確認 → 存在しない場合のみ以下を実行（スキップ禁止）
2. `Read("package.json")`, `Read("tsconfig.json")`, `Glob("*lock*")` で技術スタックを検出
3. **AskUserQuestion ツールを呼び出して** アーキテクチャパターンを選択させる（必須、テキスト質問禁止）
4. package.json がない greenfield の場合は **AskUserQuestion ツールを呼び出して** フレームワークも選択させる
5. `Write(".blueprint/config.yaml", content)` で即座に書き出す
6. `Glob(".blueprint/**/*.yaml")` `Glob(".blueprint/**/*.md")` で既存スキャン
6.5. `Glob("docs/requirements/user-stories.md")` で requirements 出力を確認
   - 存在する場合: `Read("docs/requirements/user-stories.md")` で読み込み
   - Epic/Story 構造を Contract 一覧候補のベースにする
   - ユーザーへの報告: 「要件定義が見つかりました。これを元に Contract を設計します」

**⛔ Step 3 のアーキテクチャ・フレームワーク質問は、Step 1 で AskUserQuestion を呼んだ場合は必ず省略すること**（二重質問禁止）。

---

**【Step 1 で呼ぶ AskUserQuestion — アーキテクチャ選択】**

config.yaml が存在しない場合、必ず以下の AskUserQuestion ツールを呼び出す:

- question: `"アーキテクチャパターンを選択してください"`
- header: `"Architecture"`
- options:
  - label: `"layered（推奨）"` / description: `"Routes → Services → Models の3層。中規模APIに最適"`
  - label: `"clean"` / description: `"Domain / Usecase / Interface / Infra の4層。大規模・長期運用向け"`
  - label: `"flat"` / description: `"最小構造。プロトタイプ・小規模スクリプト向け"`

---

**【Step 1 で呼ぶ AskUserQuestion — greenfield のみ】**

package.json が存在しない場合、必ず以下の AskUserQuestion ツールを呼び出す（上のアーキテクチャ選択と **同一 AskUserQuestion 呼び出し内の別 question として**まとめる）:

- question: `"バックエンドフレームワークを選択してください"`
- header: `"Backend"`
- options:
  - label: `"Hono（推奨）"` / description: `"軽量・高速。Vitest と相性◎"`
  - label: `"Express"` / description: `"エコシステムが豊富"`
  - label: `"Fastify"` / description: `"スキーマ検証内蔵・高パフォーマンス"`

- question: `"フロントエンドフレームワークを選択してください（API only なら「なし」）"`
- header: `"Frontend"`
- options:
  - label: `"React（推奨）"` / description: `"Vite + React。shadcn/ui と組み合わせ可"`
  - label: `"Next.js"` / description: `"SSR / フルスタック。APIと同一リポジトリ"`
  - label: `"なし（API only）"` / description: `"フロントエンドは別リポジトリまたは不要"`

---

`.blueprint/` が存在しない場合は、初期化スクリプトを使って構造を作成:

```bash
# プラグインの初期化スクリプトを使用（mkdir -p 直接実行は禁止）
bash "$(claude plugin-dir)/scripts/init-blueprint.sh" "$(pwd)"
```

> スクリプトのパスが取得できない場合は `mkdir -p .blueprint/{contracts,concepts,decisions}` をフォールバックとして使用。

### Step 2: スコープ確認

`core/spec.md` Step 2 に従いスコープを確認。config.yaml は Step 1 で生成済み。

**user-stories.md が存在する場合**、スコープ確認のベースにする:
- 既存のペルソナ・Epic・Story 構造を提示
- 追加・変更がないかユーザーに確認
- `/requirements` で回答済みの内容（プラットフォーム、ターゲットユーザー等）は再質問しない

**API only キーワード（API / バックエンド / サーバー / SDK / CLI / バッチ / ジョブ / スクリプト）が検出された場合のみ、AskUserQuestion ツールを呼び出してフロントエンドスコープを確認する**（それ以外はフロントエンドあり確定なので聞かない）:

- question: `"フロントエンド（UI画面）も含めますか？"`
- header: `"スコープ"`
- options:
  - label: `"含める"` / description: `"APIとUIの両方を設計する（screen Contract を生成）"`
  - label: `"APIのみ"` / description: `"バックエンドAPIのみ設計する（screen Contract をスキップ）"`

config.yaml のスキーマと検出ロジックの詳細は `core/spec.md` Step 2「config.yaml 生成」を参照。

**frontend セクション（screen Contract が生成される場合のみ追加）**:

Step 3 のブレストでユーザーが UI/画面に言及した場合、Step 5 の YAML 生成後に config.yaml に frontend セクションを追加する:

```bash
# フロントエンドフレームワーク検出
Read("package.json")  # react/vue/svelte/next のいずれかが dependencies に含まれるか確認
```

```yaml
# .blueprint/config.yaml に追記（screen Contract がある場合のみ）
tech_stack:
  # ... 既存フィールド ...
  frontend:
    framework: react   # 検出結果またはユーザー選択
    ui_library: none   # shadcn | mui | antd | none
    test_tool: testing-library  # 検出結果（デフォルト: testing-library）
```

### Step 3: ブレインストーミング

対話のコツ:
- 質問は 1 つずつ（まとめて聞かない）
- ユーザーの回答からフォローアップ質問を導出
- 具体的な値（数値範囲、パターン、列挙値）を引き出す
- 「他にエラーケースはありますか？」で網羅性を確認

### Step 4: Contract 一覧合意

`core/spec.md` Step 4 のフォーマットで Contract 一覧を提示した後、**必ず AskUserQuestion ツールを呼び出して承認を得てから次へ進む**（テキストで「よろしいですか？」と聞くのは禁止）:

- question: `"この Contract 一覧で生成に進みますか？"`
- header: `"Contract 確認"`
- options:
  - label: `"承認 — 生成に進む"` / description: `"上記一覧で Contract YAML を生成する"`
  - label: `"修正する"` / description: `"Contract の追加・削除・タイプ変更がある"`

「修正する」が選択された場合は、変更点をヒアリングして一覧を更新し、再度 AskUserQuestion ツールで確認する。

### Step 5: Contract YAML 生成

**⛔ 絶対厳守: Contract タイプルール**

| Contract の内容 | `type` の値 | `subtype` |
|----------------|------------|-----------|
| 自社 HTTP API エンドポイント（GET/POST/PATCH/DELETE 等） | `api` | なし |
| 外部 API 呼び出し（Stripe/SendGrid 等のクライアント） | `external` | なし |
| ファイル入出力（CSV 読み込み、レポート生成 等） | `file` | なし |
| データ永続化・リポジトリ（DB/インメモリ/ファイル保存） | `internal` | `repository` |
| ドメインサービス・ユーティリティ | `internal` | `service` |
| UI 画面設計（フォーム・一覧・詳細・ダッシュボード） | `screen` | `screen_type` で指定 |

❌ **禁止**: `function`、`model`、`service`（type として）、`repository`（type として）、`entity`、`endpoint` は **type に使えない**。

**screen Contract の depends_on 自動同期（必須）**:

screen Contract を生成する際、以下の値を **必ず** `links.depends_on` にも設定する:
- `form.submit_action` の値
- `list.data_source` の値
- `detail.data_source` の値
- `detail.actions[].calls` の全値（各アクションの呼び出し先 API も同期）
- `dashboard.widgets[].data_source` の全値

```yaml
# 自動同期の例
form:
  submit_action: CON-order-create    # ← ユーザーが指定
links:
  depends_on: [CON-order-create]     # ← /spec が自動で同期（必須）
```

**screen Contract テンプレート参照**:

```
Read("skills/spec/references/contract-templates/screen.yaml")
```

screen_type（form/list/detail/dashboard）に応じて不要なセクションを削除してから書き出す。

**Contract YAML の最小構造（タイプ別）**:

```yaml
# type: api の場合（HTTP エンドポイント）
id: CON-{{name}}
type: api          # ← 必ず "api" を使う（"function" は無効）
version: 1.0.0
status: draft
method: POST       # GET | POST | PUT | PATCH | DELETE
path: /todos
input:
  body:
    title: { type: string, required: true, max: 100 }
output:
  success:
    status: 201
    body:
      id: { type: string }
  errors:
    - { status: 400, code: VALIDATION_ERROR, description: "バリデーション失敗" }
business_rules:
  - { id: BR-001, rule: "title は必須で最大100文字" }
```

```yaml
# type: internal の場合（リポジトリ/サービス）
id: CON-{{name}}
type: internal     # ← 必ず "internal" を使う
subtype: repository  # または service
version: 1.0.0
status: draft
input:
  findById:
    params:
      id: { type: string, required: true }
    returns: { type: object, description: "Todo | null" }
  create:
    params:
      data: { type: object, required: true }
    returns: { type: object, description: "作成されたTodo" }
```

ブレスト結果で `{{placeholder}}` を埋め、`type` は上記ルールに従って設定すること。

**implementation セクション対話（オプション）**:

各 Contract の基本フィールド生成後、`core/spec.md` Step 5 の implementation セクション対話に従い、
data_sources と flow をユーザーと対話して決定する。ユーザーが「スキップ」と回答した場合は省略。

### Step 6: `.claude/rules/` 生成（初回のみ）

**⛔ 絶対必須: Contract 生成・副産物生成が終わったら、必ずこのステップを実行すること。スキップ禁止。**

プロジェクト規約ファイルを `.claude/rules/` に Write で生成する。

**実行手順**:

1. `Glob(".claude/rules/")` で既存チェック → 存在する場合はこのステップ全体をスキップ
2. `.blueprint/config.yaml` の `tech_stack` を確認（Step 1 で読み込み済み）
3. 各テンプレートファイルを Read して Write で書き出す

**生成ファイルとテンプレート参照**:

| 生成先 | テンプレート | 条件 |
|--------|-----------|------|
| `.claude/rules/base.md` | `{baseDir}/references/claude-rules-templates/base.md` | 常時必須 |
| `.claude/rules/typescript.md` | `{baseDir}/references/claude-rules-templates/typescript.md` | `language: typescript` |
| `.claude/rules/react.md` | `{baseDir}/references/claude-rules-templates/react.md` | `frontend.framework: react\|next` |
| `.claude/rules/testing-library.md` | `{baseDir}/references/claude-rules-templates/testing-library.md` | `frontend.test_tool: testing-library` |

```
# 実行例（base.md）
content = Read("{baseDir}/references/claude-rules-templates/base.md")
Write(".claude/rules/base.md", content)
```

> テンプレートの詳細は `{baseDir}/references/claude-rules-templates/` 配下を参照。
> `frontend` セクションが config.yaml にない場合（バックエンドのみプロジェクト）は `typescript.md` のみ生成。

### Step 7: サマリー出力

生成結果をユーザーに提示し、次のアクションを案内:

```
## 生成ファイル
- .blueprint/contracts/{type}/{name}.contract.yaml (CON-{name} v1.0.0)
- ...
- .claude/rules/base.md（初回生成時のみ）
- .claude/rules/typescript.md（TypeScript プロジェクトのみ）
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
