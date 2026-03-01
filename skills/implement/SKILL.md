---
name: implement
description: Implement code from Contract YAML and RED tests. Use when the user wants to "implement contracts", "generate implementation", "make tests green", "create implementation", or "run Stage 3". Orchestrates Implementers, Integrator, and Refactorer agents to produce working code.
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
- `architecture.pattern` が `clean` | `layered` | `flat` のいずれかであること
- `tech_stack` の必須フィールド（framework, validation, test）が設定済みであること
- 不足がある場合はユーザーに確認して補完

**implementation セクション未設定の Contract**:
- 警告を出力し、business_rules と depends_on から推定する旨を伝える

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

```
Agent({
  subagent_type: "general-purpose",
  description: "Implement CON-{name}",
  prompt: "
    ## タスク
    Contract CON-{name} の実装を行い、RED テストを GREEN にしてください。
    ディレクトリ・ファイルの作成から実装まで全て行ってください。

    ## Contract 情報（インライン）
    - Contract ID: CON-{name}
    - Type: {type}  (api | external | file | internal)
    - Tech Stack: {framework} + {validation} + {orm}
    - Architecture: {pattern}
    - 担当エンティティ: {entity}

    ## 読み込むファイル
    - Contract YAML: .blueprint/contracts/{type}/{name}.contract.yaml
    - RED テスト: tests/contracts/level2/CON-{name}.test.ts
    - 命名規約: core/defaults/naming.md
    - アーキテクチャ: core/defaults/architecture-patterns/{pattern}.md
    - エラー処理: core/defaults/error-handling.md
    - DI: core/defaults/di.md
    - バリデーション: core/defaults/validation-patterns.md

    ## 実装手順
    1. 上記ファイルを全て読み込む
    2. Contract の implementation.flow がある場合はその順序で実装
       flow がない場合は一括で実装
    3. 作成するファイル（{entity} 名前空間配下のみ）:
       - 型定義（Contract input/output から導出）
       - バリデーションスキーマ
       - ビジネスロジック（business_rules は TDD: ユニットテストを先に書く）
       - Repository interface + 実装
       - ルートファイル（method + path からルート定義）
    4. ユニットテストは tests/unit/{entity}/ に配置
    5. テスト実行: npx vitest tests/contracts/level2/CON-{name}.test.ts
    6. 全テスト GREEN になるまで修正を続ける

    ## 重要ルール
    - app.ts や DI container など共有ファイルは作成しない（Integrator が担当）
    - 自分の名前空間（{entity}）配下のファイルのみ作成・編集
    - テストが GREEN にならない場合、同じエラーが 3 回連続したらその旨を報告
    - 勝手にスキップしない
  "
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
# 全テスト一括実行（Level 1 + Level 2 + Unit）
npx vitest tests/
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

```
Agent({
  subagent_type: "general-purpose",
  description: "Refactor implementation",
  prompt: "
    ## タスク
    実装コードの構造リファクタリングを行ってください。
    あなたは実装プロセスのコンテキストを持ちません。
    フレッシュな視点でコード品質を改善してください。

    ## 読み込むファイル
    - 設計規約:
      - core/defaults/naming.md
      - core/defaults/architecture-patterns/{pattern}.md（config.yaml から取得）
      - core/defaults/error-handling.md
      - core/defaults/di.md
    - 実装コード: src/ 配下全体
    - テスト: tests/ 配下全体

    ## 実行内容
    1. core/defaults/ を読んで設計規約を把握
    2. src/ 配下の全コードを読み込み
    3. 以下の観点で改善:
       - 複数ファイルに重複するロジックの共通化
       - 共通ユーティリティの抽出
       - 命名の統一（naming.md 準拠）
       - レイヤー構造の整合性（architecture-patterns 準拠）
    4. リファクタ後、全テスト実行: npx vitest tests/
    5. テストが壊れた場合は修正（リファクタで機能を壊さない）

    ## 重要ルール
    - テストを壊さない（全 GREEN を維持）
    - 機能の追加・削除はしない（構造改善のみ）
    - 大きな変更を行う場合は変更理由をコメントで残す
  "
})
```

### Step 6: コード簡素化

```
Skill("simplify")
```

/simplify を実行し、コードの可読性・効率・再利用性を最終チェックする。

### Step 7: 承認 + pipeline-state 更新

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

Code Review Gate に進みますか？
```

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
