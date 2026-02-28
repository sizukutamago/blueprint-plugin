---
name: implement
description: Implement code from Contract YAML and RED tests. Use when the user wants to "implement contracts", "generate implementation", "scaffold project", "implement from tests", "make tests green", "create implementation", or "run Stage 3". Orchestrates Scaffolder, Implementers, and Integrator agents to produce working code.
version: 1.0.0
core_ref: core/implement.md
---

# Implement スキル (Claude Code)

Contract YAML と RED テストから実装コードを生成するスキル。
3 フェーズ（Scaffolder → Implementers → Integrator）で段階的に実装し、
ユーザー承認を 2 回挟む。

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
| `biome.json` 等 | Lint/Format 設定（オプション） |
| `.github/workflows/` | CI 設定（オプション） |

## ツール

| ツール | 用途 |
|--------|------|
| Bash | git root 検出、テスト実行、パッケージインストール |
| Glob | Contract スキャン、既存コード検出、設定ファイル検出 |
| Read | Contract YAML、config.yaml、テストファイル、core/defaults/ の読み込み |
| Write | 実装コード、設定ファイルの書き出し |
| Agent | Implementer エージェントの並列起動（Phase B） |

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
- `architecture.pattern` が `clean` | `layered` | `flat` のいずれかであること
- `tech_stack` の必須フィールド（framework, validation, test）が設定済みであること
- 不足がある場合はユーザーに確認して補完

**implementation セクション未設定の Contract**:
- 警告を出力し、business_rules と depends_on から推定する旨を伝える

### Step 2: 実装計画の生成

```
# 依存関係のトポロジカルソート
1. 全 Contract の links.depends_on を収集
2. DAG（有向非巡回グラフ）を構築
3. 循環依存チェック → エラー時は /spec での修正を案内
4. 並列実行グループを算出

ユーザーに実装計画を提示:

## 実装計画

| 順序 | Contract ID          | Type     | 依存先            | グループ |
|------|---------------------|----------|------------------|---------|
| 1    | CON-stripe-payment  | external | なし              | A       |
| 2    | CON-product-import  | file     | なし              | A       |
| 3    | CON-order-create    | api      | CON-stripe-...   | B       |

グループ A は並列実行、グループ B は A の完了後に実行します。
この計画で進めますか？
```

### Phase A: Scaffolder（メインエージェント自身が実行）

### Step 3: スキャフォールド生成

```
# config.yaml に基づく規約の読み込み
Read("core/defaults/architecture-patterns/{pattern}.md")
Read("core/defaults/naming.md")
Read("core/defaults/error-handling.md")
Read("core/defaults/di.md")
```

生成順序:
1. ディレクトリ構造（`mkdir -p` で作成）
2. 共通ファイル（`shared/errors.ts`, `shared/result.ts` 等）
3. 各 Contract の型定義（`domain/{entity}/types.ts` 等）
4. 各 Contract のバリデーションスキーマ雛形
5. 各 Contract のルート/ハンドラ雛形
6. 各 Contract の Repository interface（Clean Architecture の場合）

**依存パッケージの処理**:
```
# package.json から既存パッケージを確認
Read("package.json")

# 不足パッケージをリスト化してユーザーに提示
# 承認後にインストール
Bash("pnpm add {packages}")
```

### Step 3.5: 承認 1

```
## スキャフォールド結果

### 生成ディレクトリ
src/
  domain/order/
    types.ts
    order.repository.ts
  usecase/order/
    create-order.usecase.ts
  ...

### 生成ファイル: N 個
### 追加パッケージ: hono, zod, drizzle-orm

この構造で実装を進めますか？
- 承認 → Phase B に進む
- 修正 → 指示に従い再生成
```

### Phase B: Implementers（Agent ツールで並列起動）

### Step 4: Contract 単位の実装

各 Contract に対して Agent ツールで Implementer を起動:

```
Agent({
  subagent_type: "general-purpose",
  prompt: "Contract CON-xxx の実装を行ってください。
    入力:
    - Contract YAML: .blueprint/contracts/{type}/{name}.contract.yaml
    - RED テスト: tests/contracts/level2/CON-{name}.test.ts
    - 雛形コード: src/{layer}/{entity}/（Scaffolder 生成済み）
    - 規約: core/defaults/ 配下

    実行手順:
    1. Contract の implementation セクションを読む
    2. implementation.flow の順序に従い実装
    3. core/defaults/ の命名・構造規約に従う
    4. テスト実行: npx vitest tests/contracts/level2/CON-{name}.test.ts
    5. 全テスト GREEN になるまで修正

    ブロック条件（スキップする場合）:
    - DB スキーマが未定義で実装不能
    - 依存先 Contract が未完了
    - implementation セクションの情報不足で推定も困難"
})
```

**並列実行の管理**:
- 同一グループの Contract は並列で Agent を起動
- 各 Agent の完了を待ってから次グループを開始
- Agent がブロックを報告した場合はスキップリストに追加

**各 Implementer 完了時の出力**:
```
## CON-order-create 実装完了

- 新規ファイル: 4
- テスト結果: 31/31 GREEN
- 変更ファイル一覧:
  - src/domain/order/types.ts
  - src/usecase/order/create-order.usecase.ts
  - src/infra/order/order.repository.impl.ts
  - src/interface/order/order.route.ts
```

### Phase C: Integrator（メインエージェント自身が実行）

### Step 5: 統合検証

```bash
# 全テスト一括実行
npx vitest tests/contracts/
```

失敗テストがある場合:
1. 失敗テストの原因を分析
2. 修正を試みる（最大 3 回）
3. 修正できない場合はユーザーに報告

```
# import 循環の検出（オプション: dependency-cruiser がある場合）
npx depcruise src/ --validate
```

### Step 6: 承認 2

```
## 実装結果サマリー

### 完了状況
- 完了: 3/3 Contract
- ブロック: 0

### テスト結果
- Level 1: 45/45 GREEN
- Level 2: 93/93 GREEN

### 生成ファイル
| ディレクトリ | ファイル数 |
|------------|----------|
| src/domain/ | 6 |
| src/usecase/ | 3 |
| src/infra/ | 6 |
| src/interface/ | 3 |
| src/shared/ | 2 |

### 品質
- import 循環: なし
- 重複コード警告: 0

Code Review Gate に進みますか？
```

### Step 7: pipeline-state 更新

```
# pipeline-state.yaml を更新
Read(".blueprint/pipeline-state.yaml")
# stage_3_implement のフィールドを更新
Write(".blueprint/pipeline-state.yaml")
```

## 原則

| 原則 | 説明 |
|------|------|
| Contract が source of truth | implementation セクションに従い、AI の推測は最小限にする |
| テストが合否判定 | Level 2 テストの GREEN が実装完了の基準 |
| 規約に従う | core/defaults/ の命名・構造・パターンを遵守 |
| スキップ > スタブ | 実装できない Contract はスタブ生成せずスキップ |
| 承認 2 回 | スキャフォールド後 + 全完了後。途中は自動 |

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| config.yaml なし | `/spec` を先に実行するよう案内 |
| Contract 0 件 | `/spec` で Contract を作成するよう案内 |
| RED テストなし | `/test-from-contract` を先に実行するよう案内 |
| 循環依存 | エラー停止: `/spec` で depends_on を修正するよう案内 |
| パッケージインストール失敗 | 手動インストールを案内して続行 |
| テスト GREEN 不能（3 回試行後） | ユーザーに報告、手動修正後 `--resume` |
| Implementer タイムアウト | スキップリストに追加、ユーザーに報告 |
