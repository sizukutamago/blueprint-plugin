---
name: implement
description: Implement code from Contract YAML and RED tests. Use when the user wants to "implement contracts", "generate implementation", "make tests green", "create implementation", "write code from spec", "build feature from contract", "implement feature", "implement screen", "create page components", "implement UI from contract", or "implement Stage 3". Also use when the user says "実装する", "コードを書く", "テストをグリーンにする", "機能を実装する", "画面を実装する", or "コントラクトを実装". Orchestrates Implementers, Integrator, and Refactorer agents to produce working code for all contract types including screen/UI.
version: 2.0.0
core_ref: core/implement.md
---

# Implement スキル (Claude Code)

Contract YAML と RED テストから実装コードを生成するスキル。
3 フェーズ（Implementers → Integrator → Refactorer）で段階的に実装し、
最後に /simplify でコード品質を仕上げる。

## 仕様参照

本スキルのワークフローは `core/implement.md` に定義。
Contract スキーマは `core/contract-schema.md`（implementation セクション含む）を参照。
実装規約は `core/defaults/` 配下を参照:
- `architecture-patterns/` — ディレクトリ構造、レイヤー定義
- `naming.md` — ファイル名・クラス名・変数名
- `error-handling.md` — エラー処理パターン
- `di.md` — 依存性注入
- `testing.md` — モック戦略、テスト規約
- `db-access.md` — Repository パターン、トランザクション
- `validation-patterns.md` — Contract 制約 → スキーマ変換ルール
- `lint-rules.md` — Biome/ESLint 設定
- `ci-pipeline.md` — GitHub Actions テンプレート

## 前提条件

| 条件 | 必須 | 説明 |
|------|------|------|
| `.blueprint/config.yaml` | ○ | `/spec` で生成済みの tech stack 設定 |
| `.blueprint/contracts/` | ○ | `/spec` で生成済みの Contract YAML（implementation セクション推奨） |
| `tests/contracts/level2/` | ○ | `/test-from-contract` で生成済みの RED テスト |
| Git リポジトリ | ○ | `src/` をプロジェクトルートに配置 |

## 出力ファイル

| ディレクトリ | 内容 |
|------------|------|
| `src/` | 実装コード（architecture pattern に応じた構造） |
| `tests/unit/` | business_rules の TDD で生成したユニットテスト |
| `biome.json` 等 | Lint/Format 設定（オプション） |
| `.github/workflows/` | CI 設定（オプション） |

## ツール

| ツール | 用途 |
|--------|------|
| Bash | git root 検出、テスト実行、パッケージインストール |
| Glob | Contract スキャン、既存コード検出、設定ファイル検出 |
| Read | Contract YAML、config.yaml、テストファイル、core/defaults/ の読み込み |
| Write | 実装コード、設定ファイルの書き出し |
| Agent | Implementer / Refactorer エージェントの起動 |
| Skill | /simplify の実行 |

## ワークフロー（Claude Code 固有部分）

`core/implement.md` の 3 フェーズ + 7 ステップに従う。以下は Claude Code 固有の実行詳細:

### Step 1: コンテキスト読み込み

```bash
# git root を検出
git rev-parse --show-toplevel
```

```
# 必須ファイルの読み込み
Read(".blueprint/config.yaml")
Glob(".blueprint/contracts/**/*.contract.yaml")
Glob("tests/contracts/level2/**/*.test.*")
```

**config.yaml の検証**:
- `.blueprint/config.yaml` が存在しない場合: **エラー停止** — 「`/spec` を先に実行してください」と案内
- `architecture.pattern` が `clean` | `layered` | `flat` のいずれかであること
- `tech_stack` の必須フィールド（framework, validation, test）が設定済みであること
- 不足がある場合はユーザーに確認して補完

**implementation セクション未設定の Contract**:
- 警告を出力し、business_rules と depends_on から推定する旨を伝える

**⛔ 必須: 実行スクリプトのセットアップ**

プラグインスクリプトをユーザープロジェクトの `.blueprint/scripts/` にコピーする:

```
# 1. スクリプト内容を読み込み、ユーザープロジェクトに書き出す
Read("{plugin_dir}/scripts/verify-web-app.sh")
  → Write(".blueprint/scripts/verify-web-app.sh", <全文>)

Read("{plugin_dir}/scripts/assert-gate-completed.sh")
  → Write(".blueprint/scripts/assert-gate-completed.sh", <全文>)
```

```bash
mkdir -p .blueprint/scripts
chmod +x .blueprint/scripts/verify-web-app.sh .blueprint/scripts/assert-gate-completed.sh
echo ".blueprint/scripts/ initialized."
```

> `{plugin_dir}` は `claude plugin-dir` コマンドで取得するか、SKILL.md の `core_ref` パスの親ディレクトリを参照する。

→ `.blueprint/scripts/verify-web-app.sh` と `.blueprint/scripts/assert-gate-completed.sh` が生成される。

### Step 2: 実装計画の生成と承認

```
# 依存関係のトポロジカルソート
1. 全 Contract の links.depends_on を収集
2. DAG（有向非巡回グラフ）を構築
3. 循環依存チェック → エラー時は /spec での修正を案内
4. 並列実行グループを算出
5. 必要な依存パッケージを特定

ユーザーに実装計画を提示:

## 実装計画

| 順序 | Contract ID          | Type     | 依存先            | グループ |
|------|---------------------|----------|------------------|---------|
| 1    | CON-stripe-payment  | external | なし              | A       |
| 2    | CON-product-import  | file     | なし              | A       |
| 3    | CON-order-create    | api      | CON-stripe-...   | B       |

グループ A は並列実行、グループ B は A の完了後に実行します。

追加パッケージ: hono, zod, drizzle-orm
インストールコマンド: pnpm add hono zod drizzle-orm

この計画で進めますか？
```

**承認後**: 依存パッケージをインストール。

```bash
# パッケージインストール（承認済みのため自動実行）
pnpm add {packages}
```

### Phase A: Implementers（Agent ツールで並列起動）

### Step 3: Contract 単位の実装

各 Contract に対して Agent ツールで Implementer を起動。
**プロンプトにはハイブリッド方式で情報を渡す**: 核心情報はインライン、詳細はファイル参照。
プロンプト本文は `{baseDir}/references/implementer-prompt-template.md` を参照すること。

```
Agent({
  subagent_type: "general-purpose",
  description: "Implement CON-{name}",
  prompt: "<references/implementer-prompt-template.md の内容に {name}/{type}/{framework}/... を埋めたもの>"
})
```

**並列実行の管理**:
- 同一グループの Contract は並列で Agent を起動（1 つの応答で複数 Agent 呼び出し）
- 各 Agent の完了を待ってから次グループを開始
- Agent がブロックを報告した場合はユーザーに確認

**各 Implementer 完了時の出力**:
```
## CON-order-create 実装完了

- 新規ファイル: 4
- ユニットテスト: 2（business_rules TDD）
- Level 2 テスト結果: 31/31 GREEN
- 変更ファイル一覧:
  - src/domain/order/types.ts
  - src/usecase/order/create-order.usecase.ts
  - src/infra/order/order.repository.impl.ts
  - src/interface/order/order.route.ts
  - tests/unit/order/calculate-total.test.ts
  - tests/unit/order/validate-inventory.test.ts
```

### Phase B: Integrator（メインエージェント自身が実行）

### Step 4: 統合検証

```
実行内容:
1. app entry の結線
   - 各 Implementer が作成したルートファイルを app.ts にインポート・登録
   - DI container の構成（必要な場合）
   - 共通ミドルウェアの設定
2. 全テスト一括実行
```

```bash
# 全テスト一括実行（Level 1 + Level 2 + Unit + UI テスト）
npx vitest tests/
# screen Contract がある場合は UI テストも別途実行
# {frontend_test_runner} tests/ui/
```

失敗テストがある場合:
1. 失敗テストの原因を分析
2. 修正を試みる
3. 同じエラーが 3 回連続したらユーザーに報告

```bash
# import 循環の検出（オプション: dependency-cruiser がある場合）
npx depcruise src/ --validate
```

### Phase C: Refactorer（Agent ツールで起動、コンテキスト非共有）

### Step 5: 構造リファクタリング

Implementer・Integrator とコンテキストを共有しない独立エージェントを起動。
プロンプト本文は `{baseDir}/references/refactorer-prompt-template.md` を参照すること。

```
Agent({
  subagent_type: "general-purpose",
  description: "Refactor implementation",
  prompt: "<references/refactorer-prompt-template.md の内容に {pattern} を埋めたもの>"
})
```

### Step 6: コード簡素化

```
Skill("simplify")
```

/simplify を実行し、コードの可読性・効率・再利用性を最終チェックする。

### Step 6.5: Web App 動作確認

⛔ **スキップ禁止**（api Contract が 0 件でもスクリプトを実行して確認する）。

```bash
bash .blueprint/scripts/verify-web-app.sh
```

スクリプトが行うこと（詳細は `scripts/verify-web-app.sh` 参照）:
1. dev/start/serve スクリプトがなければ framework に合わせたサーバーファイル（src/server.ts など）を自動生成
2. 必要なアダプター（`@hono/node-server` 等）をインストール
3. サーバーをバックグラウンド起動（最大 30 秒待機）
4. api Contract の全エンドポイントに curl スモークテスト（5xx → 失敗）
5. 結果を `.blueprint/reviews/web-verification-{timestamp}.md` に保存してサーバー停止

**フロントエンド確認（HTML を返すエンドポイントがある場合）**:

```
Skill("agent-browser")
# → http://localhost:{PORT}/ を開く
# → コンソールエラーを確認・スクリーンショット添付
```

**失敗時**: サーバーログを確認して修正を試みる。解決不可の場合はユーザーに報告して Step 7 へ進む（Code Review Gate はブロックしない）。

### Step 7: 実装結果サマリー + Code Review Gate

**⛔ 絶対必須: Code Review Gate は /simplify・Web 動作確認が完了した後に必ず実行する。テスト GREEN だけで完了とみなしてはならない。**

実装完了サマリーを出力し、**Code Review Gate を必ず実行する**（スキップ不可）。

```
## 実装結果サマリー

### 完了状況
- 完了: 3/3 Contract
- ブロック: 0

### テスト結果
- Level 1: 45/45 GREEN
- Level 2: 93/93 GREEN
- Unit: 12/12 GREEN

### 生成ファイル
| ディレクトリ | ファイル数 |
|------------|----------|
| src/domain/ | 6 |
| src/usecase/ | 3 |
| src/infra/ | 6 |
| src/interface/ | 3 |
| tests/unit/ | 4 |

### 品質
- import 循環: なし
- Refactorer: 重複 2 件排除、命名 3 件修正
- /simplify: 改善 1 件
```

**重要**: テスト GREEN は「動作の正しさ」を確認するだけ。Code Review Gate は「Contract 宣言がコードに反映されているか（宣言の一致）」を検証する。**テスト GREEN でも Code Review Gate は必須**。

#### Code Review Gate（4 Agent 並列）

各 Agent へ渡す共通入力（`skills/orchestrator/references/review-prompts/code-reviewer.md` の「共通入力」セクション参照）:
- Contract YAML: `.blueprint/contracts/**/*.contract.yaml`
- ソースコード: `src/`（またはフレームワーク相当のディレクトリ）
- `core/review-criteria.md`（P0/P1/P2 定義）
- `skills/orchestrator/references/review-prompts/code-reviewer.md`（チェック手順）

4 つの Agent を**同時**（1 つの応答で並列呼び出し）:

```
Agent({
  subagent_type: "tdd-workflows:code-reviewer",
  description: "Code Review - Schema Compliance",
  prompt: "
    skills/orchestrator/references/review-prompts/code-reviewer.md の
    「Agent 1: Schema Compliance Checker」手順に従い、
    Contract フィールド制約がバリデーション層に反映されているか検証してください。
    共通入力・出力フォーマットは同ファイルの「共通入力」「共通出力フォーマット」参照。
    reviewer: 'schema-compliance'
  "
})

Agent({
  subagent_type: "tdd-workflows:code-reviewer",
  description: "Code Review - Route & Handler",
  prompt: "
    skills/orchestrator/references/review-prompts/code-reviewer.md の
    「Agent 2: Route & Handler Checker」手順に従い、
    api/external Contract の method/path と実装ルートの一致を検証してください。
    共通入力・出力フォーマットは同ファイルの「共通入力」「共通出力フォーマット」参照。
    reviewer: 'route-handler'
  "
})

Agent({
  subagent_type: "tdd-workflows:code-reviewer",
  description: "Code Review - Business Logic",
  prompt: "
    skills/orchestrator/references/review-prompts/code-reviewer.md の
    「Agent 3: Business Logic Checker」手順に従い、
    business_rules/state_transition/constraints の実装反映を検証してください。
    共通入力・出力フォーマットは同ファイルの「共通入力」「共通出力フォーマット」参照。
    reviewer: 'business-logic'
  "
})

Agent({
  subagent_type: "tdd-workflows:code-reviewer",
  description: "Code Review - Code Quality",
  prompt: "
    skills/orchestrator/references/review-prompts/code-reviewer.md の
    「Agent 4: Code Quality Checker」手順に従い、
    レイヤー構造・重複・命名規約を検証してください。
    architecture.pattern は .blueprint/config.yaml から確認してください。
    共通入力・出力フォーマットは同ファイルの「共通入力」「共通出力フォーマット」参照。
    reviewer: 'code-quality'
  "
})
```

**Gate 判定**: `core/review-criteria.md` の Gate 判定プロトコルに従う（P0=0 かつ P1≤1 → PASS、それ以外 → REVISE 最大 3 サイクル）。

```
## Code Review Gate 結果

| 項目 | P0 | P1 | P2 | 判定 | サイクル |
|------|----|----|----|----- |---------|
| Code | N  | N  | N  | PASS/REVISE | N |

### 検出事項（P2 要対応リスト）
- [対象] 問題の説明
```

**⛔ 必須チェックリスト（この順序で全て実行すること）**:

```
1. Code Review Gate（4 Agent 並列）を実行
2. Gate 結果を pipeline-state.yaml に書き込む（Write が必須、Read して確認から更新まで）:
   Read(".blueprint/pipeline-state.yaml")
   Write(".blueprint/pipeline-state.yaml")
   # 必ず以下のフォーマットで更新:
   # code_review_gate:
   #   status: passed  # or revising
   #   cycles: 1
   #   final_counts: { p0: 0, p1: 0, p2: N }
3. assert-gate-completed.sh を実行して書き込みを検証:
   bash .blueprint/scripts/assert-gate-completed.sh
4. exit 0 の場合のみ承認サマリーをユーザーに提示
```

```bash
# Step 3の実行
bash .blueprint/scripts/assert-gate-completed.sh
```

**⚠️ よくある失敗**: Gate を実行したのに pipeline-state.yaml を更新し忘れると assert スクリプトが常に exit 1 になる。必ず Write で更新すること。

## 原則

| 原則 | 説明 |
|------|------|
| Contract が source of truth | implementation セクションに従い、AI の推測は最小限にする |
| テストが合否判定 | Level 2 テストの GREEN が実装完了の基準 |
| 規約に従う | core/defaults/ の命名・構造・パターンを遵守 |
| 名前空間分離 | 各 Implementer は自分のエンティティ配下のみ編集 |
| business_rules は TDD | Contract の business_rules に対応するロジックはユニットテスト先行 |
| コンテキスト非共有 | Refactorer は実装プロセスの文脈を持たずフレッシュに評価 |
| 諦めない | テスト失敗時はスキップせず、同一エラー 3 回でユーザーに報告 |

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| config.yaml なし | `/spec` を先に実行するよう案内 |
| Contract 0 件 | `/spec` で Contract を作成するよう案内 |
| RED テストなし | `/test-from-contract` を先に実行するよう案内 |
| 循環依存 | エラー停止: `/spec` で depends_on を修正するよう案内 |
| パッケージインストール失敗 | 手動インストールを案内して続行 |
| テスト GREEN 不能（同一エラー 3 回連続） | ユーザーに報告、指示を仰ぐ |
| Implementer タイムアウト | ユーザーに報告、指示を仰ぐ |
