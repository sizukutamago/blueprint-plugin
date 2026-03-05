# Spec Workflow

Contract YAML をブレインストーミングから生成するワークフロー。
ユーザーがビジネス判断、AI が構造化を担当する。

> **前提**: `blueprint-structure.md` と `contract-schema.md` を参照。

## ワークフロー（7 ステップ）

### Step 1: コンテキスト読み込み

`.blueprint/` ディレクトリの状態を確認する。

- **存在しない場合**: ディレクトリ構造を初期化（`blueprint-structure.md` の構造に従う）
- **存在する場合**: 既存の contracts, concepts, decisions を読み込んで現状を把握

```
チェック項目:
- .blueprint/ の存在
- 既存 Contract の一覧と status
- 既存 concepts の相互リンク構造
- 既存 decisions の一覧
```

### Step 2: スコープ確認

ユーザーに「何を作る/変更するか」を確認する。

```
確認事項:
- 対象機能/ドメイン
- 新規か既存の変更か
- 影響範囲（既存 Contract への影響）
```

既存 Contract がある場合、関連する Contract を一覧で提示する。

#### config.yaml 生成（初回のみ）

`.blueprint/config.yaml` が存在しない場合、プロジェクトの技術スタックを検出・確認して生成する。
既に存在する場合はスキップ。

```
検出ロジック:
1. package.json, tsconfig.json, lock ファイル等からプロジェクトの技術構成を検出
2. 検出結果をユーザーに提示して確認
3. 未検出項目はユーザーに選択を求める
4. architecture.pattern はユーザーに選択を求める（clean / layered / flat）
```

```
ユーザーへの提示フォーマット:
## プロジェクト設定 (.blueprint/config.yaml)

| 項目 | 検出値 | 確認 |
|------|--------|------|
| language | typescript | ✓ 自動検出 |
| runtime | node | ✓ 自動検出 |
| framework | hono | ✓ 自動検出 |
| orm | drizzle | ✓ 自動検出 |
| validation | zod | ✓ 自動検出 |
| test | vitest | ✓ 自動検出 |
| architecture | — | ← ユーザー選択: clean / layered / flat |

→ 変更がなければ Enter、修正がある項目を教えてください。
```

**検出方法の詳細**:

| 検出対象 | 検出方法 |
|---------|---------|
| language | `tsconfig.json` の存在 → typescript、なければ javascript |
| package_manager | `pnpm-lock.yaml` / `yarn.lock` / `package-lock.json` / `bun.lockb` |
| framework | `package.json` の dependencies キーワード |
| orm | `package.json` の dependencies + `prisma/schema.prisma` 等 |
| validation | `package.json` の dependencies |
| test | `package.json` の devDependencies |
| lint | `biome.json` / `.eslintrc*` の存在 |
| ci | `.github/workflows/` の存在 |
| frontend.framework | `package.json` の dependencies（react/vue/svelte/next 等） |
| frontend.ui_library | `package.json` の dependencies（@shadcn/ui/@mui/material/antd 等） |
| frontend.test_tool | `package.json` の devDependencies（@testing-library/react 等） |
| frontend.e2e_tool | `package.json` の devDependencies（@playwright/test / cypress 等） |

スキーマの詳細は `implement.md` の config.yaml スキーマを参照。

**frontend セクション（screen Contract が存在する場合に生成）**:

```yaml
tech_stack:
  # ... 既存フィールド ...
  frontend:
    framework: react | vue | svelte | next | none  # package.json から自動検出
    ui_library: shadcn | mui | antd | none
    test_tool: testing-library | playwright | none  # デフォルト: testing-library
    e2e_tool: playwright | cypress | none           # デフォルト: none（自動検出）
```

frontend セクションは screen Contract が 1 つ以上生成される場合のみ追加する。
screen が存在しない場合はスキップ（バックエンド専用プロジェクトに余分なフィールドを追加しない）。

`e2e_tool` の検出ロジック:
- `package.json` の devDependencies に `@playwright/test` → `playwright`
- `package.json` の devDependencies に `cypress` → `cypress`
- 未検出の場合 → `none`

**greenfield の場合**（package.json もない場合）:
- 全項目をユーザーに質問
- デフォルト推奨: TypeScript + Hono + Zod + Vitest + pnpm + Clean Architecture
- screen Contract がある場合: React + shadcn/ui + testing-library

### Step 3: ブレインストーミング

ユーザーと対話してビジネスルール、エッジケース、エラーパターンを深掘りする。

**AI が質問する観点**:
- 正常系のフロー
- 入力のバリデーションルール（型、範囲、パターン）
- 異常系・エラーケース
- 状態遷移（あれば）
- 外部依存（外部 API、ファイル連携）
- ビジネスルール（金額計算、在庫管理等の業務ロジック）
- 非機能要件（タイムアウト、リトライ、冪等性）

**screen Contract が必要な場合**（ユーザーが「画面」「UI」「フロントエンド」に言及した時）:
API 設計が完了した後に以下を追加で質問する（API → screen の順序を守る）。

- 画面の種類（フォーム・一覧・詳細・ダッシュボード）
- フォームの場合: どのフィールドがあり、それぞれの制約は何か
- 一覧の場合: フィルター・ソート・ページネーションの仕様
- 認証が必要か（ログインが必要な画面か）
- アクセス可能なロールは何か
- エラー時の表示はどうするか

**終了条件**:
- 最大 **10 質問** まで（各質問はフォーカスを持つ）
- ユーザーが「十分」「次に進んで」等で終了を宣言
- 未解決の論点は `open_questions` リストに退避して次へ進む

**出力**: ブレスト結果のサマリー（構造化テキスト）

### Step 4: Contract 一覧合意

ブレスト結果から生成すべき Contract の一覧を提案する。

```
提案フォーマット:
| # | Contract ID | タイプ | 概要 | 依存先 |
|---|------------|--------|------|--------|
| 1 | CON-order-create | api | 注文作成 API | CON-stripe-payment-intent |
| 2 | CON-stripe-payment-intent | external | Stripe 決済 | — |
| 3 | CON-order-repository | internal (repository) | 注文永続化 | — |
```

**タイプ判定基準**:
- 自社が HTTP エンドポイントを公開する → `api`
- 他社 API を呼び出す → `external`
- ファイルの入出力 → `file`
- 外部に公開しないモジュール間の I/O 境界 → `internal`
  - ドメインサービス・ユーティリティ → `subtype: service`
  - データ永続化（Repository） → `subtype: repository`
- UI 画面設計（フォーム・一覧・詳細・ダッシュボード） → `screen`
  - `screen_type` を同時に決定: `form` / `list` / `detail` / `dashboard`
  - **必ず対応する API Contract を先に確定してから** screen を追加する

ユーザーの承認を得てから次へ進む。

### Step 5: Contract YAML 生成

承認された Contract 一覧に基づき、テンプレートを使って YAML を生成する。

```
生成手順:
1. タイプに対応するテンプレートを読み込む
2. ブレスト結果から各フィールドを埋める
3. links の depends_on / impacts を設定
4. business_rules / constraints / processing_rules を設定
5. implementation セクションを対話で決定（下記参照）
6. ファイルに書き出す
7. screen Contract を 1 件以上書き出した場合: config.yaml の frontend セクションを直ちに更新する（下記参照）
```

**screen 生成後の config.yaml 即時更新（Step 7）**:

screen Contract を書き出すたびに、完了後すぐ `.blueprint/config.yaml` の `tech_stack.frontend` セクションを追加・更新する。
全 Contract を生成し終わってからではなく、**最初の screen Contract 書き出し直後に 1 回実行**する。

```
実行手順:
1. .blueprint/config.yaml を読み込む
2. tech_stack.frontend セクションが未存在 → 追加
   既存 → e2e_tool のみ上書き（他フィールドは保持）
3. e2e_tool: package.json devDependencies を検出して設定
4. .blueprint/config.yaml を書き出す
```

> この即時更新により、`/test-from-contract` が Step 1 で config.yaml を読んだ時点で
> `e2e_tool` が正しく設定されており、Step 5.5 の E2E テスト生成条件が確実に判定できる。

**配置先**:
- `api` → `.blueprint/contracts/api/{name}.contract.yaml`
- `external` → `.blueprint/contracts/external/{name}.contract.yaml`
- `file` → `.blueprint/contracts/file/{name}.contract.yaml`
- `internal` → `.blueprint/contracts/internal/{name}.contract.yaml`
- `screen` → `.blueprint/contracts/screen/{name}.contract.yaml`

**screen Contract の depends_on 自動同期**:
/spec は screen Contract を生成する際、以下の値を `links.depends_on` に自動コピーする
（`/implement` のトポロジカルソートで API より先に screen が実装されるのを防ぐため）。

| screen_type | 自動同期するフィールド |
|---|---|
| form | `form.submit_action` |
| list | `list.data_source` |
| detail | `detail.data_source`、`detail.actions[].calls`（全アクション） |
| dashboard | `dashboard.widgets[].data_source`（全ウィジェット） |

```yaml
# ユーザーが指定（submit_action のみ）
form:
  submit_action: CON-order-create

# /spec が自動で links.depends_on にも反映
links:
  depends_on: [CON-order-create]  ← 自動同期
```

**SemVer 初期値**: `1.0.0`（新規の場合）

#### implementation セクション対話（オプション）

各 Contract の基本フィールド（input/output/errors/business_rules）を埋めた後、
実装に必要な内部設計情報（data_sources + flow）をユーザーと対話して決定する。

> スキーマの詳細は `contract-schema.md` の「implementation セクション」を参照。

```
対話フロー（各 Contract ごと）:

1. data_sources の特定:
   「この Contract の business_rules を実行するために、
     どのデータソースからデータを取得しますか？」
   - 各 business_rule / processing_rule / constraint に対して:
     - 「{rule の内容} を実行するために必要なデータは？」
     - entity（取得元エンティティ）、field（フィールド名）を確認
     - access 方法（db / api / cache / config）を確認
     - 排他制御や結合条件などの notes を確認

2. flow の特定:
   「この Contract の処理フローを順番に教えてください」
   - ユーザーの回答から step 番号と action を構造化
   - 各ステップに対応する business_rule を紐付け
   - 外部 Contract 呼び出し（calls）があればリンク
   - トランザクション境界を確認:
     「このステップ群はトランザクションで囲む必要がありますか？」

3. ユーザー確認:
   構造化した implementation セクションを提示して確認
```

**スキップ条件**:
- ユーザーが「implementation は後で」「スキップ」と回答した場合
- `/implement` で AI が推定するが、精度は下がる旨を告知

### Step 6: 副産物生成

ブレスト中に出たドメイン知識と設計判断を `.blueprint/` に書き出す。

**concepts/**:
- ブレストで登場した主要ドメイン概念ごとに 1 ファイル
- frontmatter: `id`, `links`
- 本文: 概念の説明、構成要素、ビジネス上の注意、相互リンク `[[]]`

**decisions/**:
- ブレストで判断した技術選択・設計方針ごとに 1 ファイル
- ADR 形式: Context / Decision / Reason / Alternatives Considered / Consequences
- frontmatter: `id`, `status: accepted`, `date`, `links`

> concepts/decisions はブレスト中に自然に出てくるもの。「何を作るか」ではなく「なぜそうするか」の記録。

**`.claude/rules/` 生成（初回のみ）**:

`.claude/rules/` が存在しない場合、`config.yaml` の `tech_stack` に基づいてコード規約ファイルを生成する。

| 生成条件 | 出力ファイル | 内容 |
|---------|------------|------|
| 常時 | `.claude/rules/base.md` | アーキテクチャ依存ルール、Contract整合性、レビューチェックリスト |
| `language: typescript` | `.claude/rules/typescript.md` | TypeScript 型安全・命名規約 |
| `frontend.framework: react\|next` | `.claude/rules/react.md` | React コンポーネント設計規約 |
| `frontend.test_tool: testing-library` | `.claude/rules/testing-library.md` | @testing-library テスト規約 |

生成したファイルはユーザーが自由に編集・追記できる。
`.claude/rules/` が既に存在する場合はスキップする（既存の規約を上書きしない）。

### Step 7: サマリー出力

生成結果をまとめて次のアクションを提示する。

```
## 生成ファイル
- .blueprint/contracts/api/{name}.contract.yaml (CON-{name} v1.0.0)
- .blueprint/concepts/{concept}.md
- .blueprint/decisions/DEC-{NNN}-{name}.md
- ...

## 次のステップ
テストを生成するには: `/test-from-contract`
- 対象 Contract: {生成した Contract ID の一覧}
- 選択モード: all_active（status: active の全 Contract）

## 未解決事項
- {open_questions があれば列挙}
```

## 原則

| 原則 | 説明 |
|------|------|
| ユーザーがビジネス判断 | AI は質問・構造化・テンプレート埋めを担当。ビジネスルールはユーザーが決める |
| Contract は小さく | 1 つの Contract = 1 つの I/O 境界。巨大な Contract は分割を提案する |
| テスト可能性 | 全フィールドにテスト導出可能な制約を含める。曖昧な記述は具体化を求める |
| 既存の尊重 | 既存 Contract への影響を常に確認し、破壊的変更は明示する |
| YAGNI | 必要になるまで作らない。将来の拡張より現在の明確さを優先 |

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| .blueprint/ 初期化失敗 | git root でない場合の案内、権限確認 |
| ブレストが収束しない | 10 質問上限 + open_questions への退避 |
| タイプ判定が曖昧 | ユーザーに判断を委ねる |
| 既存 Contract との依存が不明確 | 明示的に確認、不明な場合は TODO リンクとして残す |
