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

```
# 1. config.yaml の存在チェック（最初に実行）
Glob(".blueprint/config.yaml")
→ 存在しない場合: 以下の手順で即座に生成（スキップ禁止）

# 2. 技術スタック検出
Read("package.json") if exists
Read("tsconfig.json") if exists
Glob("*lock*")

# 3. ユーザーに技術スタックと architecture.pattern を確認
#    （package.json がない場合は「未設定」として提示）
#    architecture.pattern: clean / layered / flat — ユーザーが選択必須

# 4. config.yaml を Write で書き出す（この後すぐ実行）
Write(".blueprint/config.yaml", {content})

# 5. 既存 .blueprint/ のスキャン
Glob(".blueprint/**/*.yaml")
Glob(".blueprint/**/*.md")
```

`.blueprint/` が存在しない場合は、初期化スクリプトを使って構造を作成:

```bash
# プラグインの初期化スクリプトを使用（mkdir -p 直接実行は禁止）
bash "$(claude plugin-dir)/scripts/init-blueprint.sh" "$(pwd)"
```

> スクリプトのパスが取得できない場合は `mkdir -p .blueprint/{contracts,concepts,decisions}` をフォールバックとして使用。

### Step 2: スコープ確認

`core/spec.md` Step 2 に従いスコープを確認。

config.yaml は Step 1 で生成済みのため、ここではブレストのスコープ（対象機能・画面）を確認するだけでよい。
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
3. 以下の内容を Write で直接書き出す（外部ファイルの Read 不要）

**生成ファイル（内容はそのままコピーして Write すること）**:

#### `.claude/rules/base.md`（常時、必須）

```markdown
# プロジェクト規約 — ベース

このプロジェクトは `.blueprint/contracts/` に Contract YAML で I/O 境界を定義している。
コードを変更する前に必ず対応する Contract を確認すること。

## アーキテクチャ依存ルール

```
domain ← usecase ← infra
domain ← usecase ← interface
```

- `domain/` は他のどの層にも依存しない（純粋なビジネスルール）
- `usecase/` は `domain/` のみに依存する
- `infra/` は `domain/` と `usecase/` に依存する
- `interface/` は `domain/` と `usecase/` に依存する
- 逆方向の依存（domain → usecase など）は禁止

## Contract との整合性

- 実装が Contract の `business_rules` を全て満たすこと
- Contract の `input` / `output` スキーマと実装の型が一致すること
- Contract に記載のないエラーコードを新たに追加する場合は Contract も更新すること

## エラー処理

- エラーは型で表現する（`throw new Error('文字列')` ではなく typed error class）
- 外部境界でのみ catch する（usecase / interface 層のエントリポイント）
- エラーメッセージはユーザー向け（ja）と開発者向け（ログ）を分ける

## レビュー観点チェックリスト

実装を行う際、以下を確認すること:

- [ ] Contract の全 `business_rules` が実装に反映されているか
- [ ] バリデーションが Contract の `constraints` / `validation_rules` と一致するか
- [ ] エラーレスポンスが Contract の `output.errors` と一致するか
- [ ] 新規ファイルが正しい層に配置されているか（依存ルール違反なし）
- [ ] テストが Level 1（構造）+ Level 2（実装）の両方をカバーしているか
```

#### `.claude/rules/typescript.md`（`language: typescript` の場合）

```markdown
---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---

# TypeScript 規約

## 型安全

- `any` 禁止。型が不明な場合は `unknown` を使い、型ガードで絞り込む
- 外部入力（API リクエスト、ファイル読み込み等）は必ず Zod 等でバリデーション後に型付けする
- `as` キャストは原則禁止。型ガード関数か Zod の `safeParse` で代替する
- `!`（non-null assertion）は原則禁止。`if` チェックか `??` で代替する

## 型定義のルール

- Zod スキーマから型を導出する: `type Foo = z.infer<typeof FooSchema>`
- 同じ構造の型を2箇所以上定義しない（domain/ の型を全層で共有する）
- export する関数には明示的な戻り値の型を付ける

## 命名規約

| 対象 | 規約 | 例 |
|------|------|-----|
| クラス / interface / type | PascalCase | `{Entity}Repository`, `Create{Entity}Input` |
| 関数 / メソッド / 変数 | camelCase | `create{Entity}`, `findById` |
| 定数 | UPPER_SNAKE_CASE | `MAX_TITLE_LENGTH` |
| ファイル | kebab-case | `{entity}.repository.ts` |
| テストファイル | `{対象}.test.ts(x)` | `{entity}.repository.test.ts` |

## 禁止パターン

- `console.log` を本番コードに残す（`console.error` / ロガーを使う）
- 空の `catch` ブロック（必ず処理を記述する）
- `Promise` を `await` せず放置する（`void` を付けるか `await` する）
```

#### `.claude/rules/react.md`（`frontend.framework: react|next` の場合）

```markdown
---
paths:
  - "src/**/*.tsx"
  - "src/interface/**"
---

# React コンポーネント規約

## コンポーネント設計

- **Props-based design**: API 呼び出しや副作用を props（`onSubmit`, `onSuccess` 等）で注入し、
  コンポーネント内部でフェッチしない（テスト容易性のため）
- コンポーネントは `src/interface/{feature-name}/` に配置する
- ページコンポーネント: `{FeatureName}Page.tsx`
- 再利用コンポーネント: `{FeatureName}/components/{ComponentName}.tsx`

## 命名規約

| 対象 | 規約 | 例 |
|------|------|-----|
| コンポーネント関数 | PascalCase | `{Entity}ListPage` |
| Props 型 | `{ComponentName}Props` | `{Entity}ListPageProps` |
| `data-testid` | kebab-case | `title-input`, `submit-button` |
| カスタムフック | `use` + PascalCase | `use{Entity}Form` |

## テスト容易性

- フォームの `submit` 先は `onSubmit?: (data: T) => Promise<void>` として props で受け取る
- 成功コールバックは `onSuccess?: () => void` として props で受け取る
- `data-testid` は Contract の `form.fields` のフィールド名に準拠する

## アクセシビリティ

- ボタンは `aria-busy` で送信中状態を表現する（`disabled` と併用）
- エラーメッセージには `role="alert"` を付与する
- フォームフィールドには `<label>` を関連付ける

## 禁止パターン

- コンポーネント内での直接 `fetch` / `axios` 呼び出し
- `useEffect` での初期データ取得（ローダーパターンまたは RSC を使う）
- inline style（Tailwind クラスまたは CSS Modules を使う）
```

#### `.claude/rules/testing-library.md`（`frontend.test_tool: testing-library` の場合）

```markdown
---
paths:
  - "tests/ui/**"
  - "**/*.test.tsx"
---

# @testing-library テスト規約

## クエリ優先順位（高→低）

1. `getByRole` — アクセシビリティロールで取得（最優先）
2. `getByLabelText` — ラベルテキストで取得
3. `getByText` — テキスト内容で取得
4. `getByTestId` — `data-testid` で取得（最終手段、Contract フィールド名に準拠）

## イベント操作

- `userEvent` を使う（`fireEvent` は原則禁止）
- テスト冒頭で `const user = userEvent.setup()` を初期化する

## 非同期アサーション

- `waitFor` 内には1つのアサーションのみ記述する

## テスト構成

- `describe` ブロックは Contract の ID とセクション（VR-001〜 / BR-001〜）に対応させる
- テスト名は Contract の `validation_rules[].id` または `business_rules[].id` を含める

## モック / beforeEach

- `vi.fn()` でコールバック props をモック
- 各テスト前に `vi.resetAllMocks()` を呼ぶ
```

> **注**: `frontend` セクションが config.yaml にない場合（バックエンドのみプロジェクト）は `typescript.md` のみ生成。

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
