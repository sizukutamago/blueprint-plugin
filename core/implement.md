# Implement Workflow

Contract YAML + RED テストから実装コードを生成するワークフロー。
3 フェーズ（Scaffolder → Implementers → Integrator）で段階的に実装する。

> **前提**: `contract-schema.md`、`test-from-contract.md`、`blueprint-structure.md` を参照。

## ワークフロー（3 フェーズ + 7 ステップ）

### Step 1: コンテキスト読み込み

プロジェクトの状態を把握する。

```
実行内容:
1. .blueprint/config.yaml を読み込み（tech stack、architecture pattern）
2. .blueprint/contracts/ の全 Contract をスキャン
   - implementation セクションの有無を確認
   - links.depends_on を収集
3. tests/contracts/ の RED テスト（Level 2）を確認
4. 既存コードの構造を把握（brownfield の場合）
```

**config.yaml が存在しない場合**:
- エラー: 「/spec を先に実行して config.yaml を生成してください」
- config.yaml は `/spec` 実行時に生成される

**implementation セクションがない Contract**:
- 警告: 「CON-xxx に implementation セクションがありません。AI が処理フローを推定します」
- 可能な限り business_rules と depends_on から推定するが、精度は下がる

### Step 2: 実装計画の生成

Contract の依存関係から実装順序を決定する。

```
実行内容:
1. depends_on でトポロジカルソート
   - 循環依存を検出した場合はエラー（/spec で修正が必要）
2. 並列実行可能なグループを特定
   - 依存なし Contract は同一グループ（並列実行可能）
   - 依存あり Contract は依存先の完了後に実行
3. 実装計画をユーザーに提示

提示フォーマット:
| 順序 | Contract ID          | Type     | 依存先            | 並列グループ |
|------|---------------------|----------|------------------|------------|
| 1    | CON-stripe-payment  | external | なし              | A          |
| 2    | CON-order-create    | api      | CON-stripe-...   | B          |
| 3    | CON-product-import  | file     | なし              | A          |
```

## Phase A: Scaffolder（1 エージェント、逐次実行）

### Step 3: スキャフォールド生成

config.yaml と Contract から プロジェクトの骨格を生成する。

```
実行内容:
1. architecture pattern に基づくディレクトリ構造を生成
2. 全 Contract の input/output から型定義を生成
3. バリデーションスキーマの雛形を生成（tech_stack.validation に準拠）
4. 各 Contract の Route/Handler ファイルの雛形を生成
5. core/defaults/ の規約に基づいて命名・構造を決定
6. 依存パッケージリストを生成

オプション（config.yaml で有効化時のみ）:
- lint 設定ファイル生成（biome.json, .eslintrc 等）
- CI ワークフロー生成（.github/workflows/）
```

**ディレクトリ構造例（Clean Architecture + TypeScript + Hono）**:

```
src/
  domain/{entity}/
    types.ts              ← Contract input/output から型を導出
    {entity}.repository.ts ← interface のみ（中身は Implementer）
  usecase/{entity}/
    {action}-{entity}.ts   ← UseCase interface + 雛形
  infra/{entity}/
    {entity}.repository.impl.ts  ← Repository 実装の雛形
    {entity}.schema.ts            ← Zod スキーマの雛形
  interface/{entity}/
    {entity}.route.ts      ← Contract の method/path からルート定義
```

**依存パッケージリスト例**:

```
必須:
- hono (framework)
- zod (validation)
- drizzle-orm (ORM)

開発:
- vitest (test)
- @types/node

インストールコマンド: pnpm add hono zod drizzle-orm
```

### Step 3.5: 承認 1（スキャフォールド確認）

ユーザーにスキャフォールド結果を提示して承認を得る。

```
提示内容:
1. 生成したディレクトリ構造
2. 型定義の一覧
3. 依存パッケージリスト
4. 実装計画（Step 2 の再掲）

ユーザーの選択肢:
- 承認: Phase B（実装）に進む
- 修正: 具体的な修正指示を受けて再生成
- 中止: パイプラインを停止
```

**承認後**: 依存パッケージをインストール（ユーザー確認済みのため自動実行）。

## Phase B: Implementers（N エージェント、並列実行）

### Step 4: Contract 単位の実装

各 Implementer は 1 つの Contract を担当し、RED テストを GREEN にする。

```
各 Implementer の実行内容:
1. 担当 Contract の implementation セクションを読み込み
2. 対応する RED テスト（Level 2）を読み込み
3. core/defaults/ の規約を参照
4. implementation.flow の順序に従って実装:
   a. バリデーション実装（Contract 制約 → スキーマ）
   b. ビジネスロジック実装（business_rules + data_sources）
   c. ルート/ハンドラ配線（method + path）
5. 担当テストを実行して GREEN を確認
```

**Implementer の入力**:

| 入力 | 情報源 |
|------|-------|
| I/O 定義 | Contract YAML（input/output/errors） |
| 内部設計 | Contract YAML（implementation セクション） |
| 期待動作 | tests/contracts/ の RED テスト（Level 2） |
| tech stack | .blueprint/config.yaml |
| 命名・構造規約 | core/defaults/ |
| 雛形コード | Scaffolder が生成したファイル |

**並列実行ルール**:
- トポロジカルソートの同一グループは並列実行可能
- 依存先が完了するまで待機（依存先がスキップされた場合は自身もスキップ）
- 各エージェントは Scaffolder が生成した自分の担当ファイルのみ編集

**Contract タイプ別の実装内容**:

| タイプ | 主な実装内容 |
|--------|------------|
| api | ルート定義、バリデーション、UseCase、Repository |
| external | API クライアント、リトライロジック、エラーハンドリング |
| file | パーサー、行バリデーション、バルク処理 |

### Step 4.5: ブロック処理

Implementer が実装できない場合の処理。

```
ブロック条件:
- DB スキーマが未定義で data_source.access: db の実装ができない
- 依存先 Contract がスキップされた
- 外部 API のモック情報が不足
- implementation セクションの情報が不足

ブロック時の処理:
1. ブロック理由を記録
2. 担当 Contract をスキップ
3. 次の Contract の実装に移行（他の Implementer が処理）
```

**ブロック記録フォーマット**:

```yaml
blocked:
  - contract_id: CON-xxx
    reason: "missing_schema"          # missing_schema | dependency_skipped | insufficient_info | mock_needed
    detail: "products テーブルのスキーマが未定義"
    required_input: "DB スキーマ定義 or Prisma/Drizzle のスキーマファイル"
```

## Phase C: Integrator（1 エージェント、逐次実行）

### Step 5: 統合検証

全 Implementer の成果を統合して品質を確認する。

```
実行内容:
1. 全テスト一括実行（Level 1 + Level 2）
   - 失敗テストがあれば修正を試みる（最大 3 回）
   - 修正できない場合はユーザーに報告
2. ブロックされた Contract のリスト提示
3. import 循環の検出（レイヤー違反チェック）
4. 明らかな重複コードの検出
```

### Step 6: 承認 2（実装完了確認）

ユーザーに実装結果を提示して承認を得る。

```
提示内容:
1. 実装サマリー:
   - 完了 Contract 数 / 全 Contract 数
   - 新規ファイル数、変更ファイル数
   - テスト結果（GREEN 数 / 全テスト数）
2. ブロックリスト（ある場合）:
   - 各 Contract のブロック理由と必要な入力
3. 品質レポート:
   - import 循環の有無
   - 重複コード検出結果

ユーザーの選択肢:
- 承認: Code Review Gate に進む
- 修正: 具体的な修正指示を受けて再実行
- 中止: パイプラインを停止（成果物は保持）
```

**Stage 3 の終了状態**:

| 状態 | 条件 | 次のアクション |
|------|------|--------------|
| success | 全 Contract 完了 + 全テスト GREEN | Code Review Gate へ |
| partial | ブロックあり + 他は GREEN | ブロックリスト提示、ユーザー判断 |
| failed | テスト修正不能 | ユーザーに報告、手動修正後 --resume |

### Step 7: pipeline-state 更新

```yaml
stage_3_implement:
  status: completed | partial | failed
  scaffolder:
    generated_dirs: N
    generated_files: N
    packages_installed: [...]
  implementers:
    total_contracts: N
    completed: N
    skipped: N
    blocked: [...]                  # ブロックリスト
  integrator:
    test_results: { pass: N, fail: N }
    circular_imports: N
    duplicate_code_warnings: N
  approval_1: accepted | modified   # スキャフォールド承認結果
  approval_2: accepted | modified   # 実装完了承認結果
```

## エラーハンドリング

| エラー | 対処 |
|--------|------|
| config.yaml が存在しない | エラー停止: `/spec` を先に実行するよう案内 |
| Contract に implementation セクションがない | 警告 + AI 推定で続行 |
| 循環依存の検出 | エラー停止: `/spec` で依存関係を修正するよう案内 |
| テスト GREEN にできない（3 回試行後） | ユーザーに報告、手動修正を案内 |
| 依存パッケージのインストール失敗 | エラー表示 + 手動インストールを案内 |
| Implementer がタイムアウト | 該当 Contract をスキップ、ブロックリストに追加 |

## config.yaml スキーマ

`/spec` の Step 2 で生成される。Scaffolder と Implementer が参照する。

```yaml
# .blueprint/config.yaml
project:
  name: "プロジェクト名"
  language: typescript | javascript       # 検出 or ユーザー指定
  runtime: node | deno | bun              # 検出 or ユーザー指定

architecture:
  pattern: clean | layered | flat          # ユーザー選択
  # pattern ごとのレイヤー定義は core/defaults/architecture-patterns/ を参照

tech_stack:
  framework: hono | express | fastify | next | none   # 検出 or 選択
  orm: drizzle | prisma | typeorm | none               # 検出 or 選択
  validation: zod | joi | yup | class-validator        # 検出 or 選択
  test: vitest | jest                                   # 検出 or 選択
  package_manager: pnpm | npm | yarn | bun             # 検出

quality:
  lint: biome | eslint | none              # 検出 or 選択
  format: biome | prettier | none          # 検出 or 選択
  type_check: true | false                 # tsconfig.json の存在で検出
  ci:
    enabled: true | false
    provider: github-actions | none        # .github/ の存在で検出
    pre_commit: [lint, type_check]         # オプション
    pr: [lint, type_check, test]           # オプション
```

**検出ロジック**（brownfield 対応）:

| 検出対象 | 検出方法 |
|---------|---------|
| language | `tsconfig.json` の存在 → typescript、なければ javascript |
| package_manager | `pnpm-lock.yaml` / `yarn.lock` / `package-lock.json` / `bun.lockb` |
| framework | `package.json` の dependencies キーワード |
| orm | `package.json` の dependencies + `prisma/schema.prisma` 等 |
| lint | `biome.json` / `.eslintrc*` の存在 |
| ci | `.github/workflows/` の存在 |

**手動オーバーライド**: config.yaml を直接編集すれば、検出結果を上書きできる。
