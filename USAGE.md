# blueprint-plugin 詳細ガイド

## このプラグインが解決する問題

AI にコードを書かせると、仕様が曖昧なまま実装が始まり、後から「これ違う」の手戻りが起きがちです。
blueprint-plugin は **要件を定義する → 仕様を固める → テストで仕様を検証可能にする → テストが通る実装を生成する** という順序を強制することで、この問題を構造的に解消します。

さらに、使い続けるとログが蓄積され、「Gate でいつも同じ指摘が出る」「ユーザーがいつも同じ修正をしている」といったパターンをプラグイン自身が検出し、改善 PR を提案します。

---

## 目次

### パイプライン — 「何を作るか」を決めて、作って、文書化する

1. [/blueprint — 全自動パイプライン](#1-blueprint--全自動パイプライン)
2. [/requirements — 要件をユーザーストーリーで定義する](#2-requirements--要件をユーザーストーリーで定義する)
3. [/spec — 仕様を会話で固める](#3-spec--仕様を会話で固める)
4. [/test-from-contract — 仕様をテストに変換する](#4-test-from-contract--仕様をテストに変換する)
5. [/implement — テストが通る実装を生成する](#5-implement--テストが通る実装を生成する)
6. [/generate-docs — コードから設計書を後追い生成する](#6-generate-docs--コードから設計書を後追い生成する)

### 品質 — 各ステージの出力をチェックする仕組み

7. [Review Gate — AI の出力を AI がレビューする](#7-review-gate--ai-の出力を-ai-がレビューする)

### 自己改善 — プラグイン自体を良くしていく

8. [/blueprint-improve — 使用ログから改善案を生成する](#8-blueprint-improve--使用ログから改善案を生成する)

### リファレンス

9. [Contract YAML の書き方](#9-contract-yaml-の書き方)
10. [アーキテクチャパターン](#10-アーキテクチャパターン)
11. [既存プロジェクトへの適用](#11-既存プロジェクトへの適用)
12. [トラブルシューティング](#12-トラブルシューティング)

---

## 1. /blueprint — 全自動パイプライン

### なぜあるのか

5つのステージ（/requirements → /spec → /test-from-contract → /implement → /generate-docs）を毎回手動で呼ぶのは面倒です。`/blueprint` はこれを1コマンドで順番に実行し、各ステージ間で Review Gate を自動挿入します。途中で止まっても `--resume` で再開できるので、長いパイプラインでも安心です。

### 何をするか

```
/requirements       → ユーザーストーリーを定義
    ↓ Requirements Gate（3 エージェント並列レビュー）
/spec              → Contract YAML を生成
    ↓ Contract Gate（3 エージェント並列レビュー）
/test-from-contract → Level 1/2 テストを生成
    ↓ Test Gate
/implement          → 実装コードを生成
    ↓ Code Gate（4 エージェント並列レビュー）
/generate-docs      → 設計書を生成
    ↓ Doc Gate
```

各 Gate で **P0=0 かつ P1≤1** なら PASS。それ以外は自動修正サイクル（最大 3 回）。

### どう使うか

```bash
# 基本: プロジェクトルートで実行し、質問に答えていく
/blueprint

# 途中で止まった・コンテキストが切れた場合
/blueprint --resume

# 全ステージをゼロからやり直す場合
/blueprint --force
```

### いつ使うか

- **新規プロジェクト**: 最初から `/blueprint` で始めるのが最も効率的
- **機能追加**: 既存の `.blueprint/` がある状態で `/blueprint` を実行すると、差分だけ処理される
- **やり直し**: `--force` で全ステージを強制再実行

---

## 2. /requirements — 要件をユーザーストーリーで定義する

### なぜあるのか

「○○を作って」と言って `/spec` に入ると、Claude が仕様を想像で埋めてしまいがちです。`/requirements` は **実装仕様の前に「誰のために・何を・なぜ作るか」を構造化する** ステージです。

Double Diamond プロセス（発散→収束→発散→収束）で要件を整理し、ユーザーストーリー + 受け入れ条件（AC）を EARS-inspired 記法で定義します。この成果物が `/spec` の入力になり、Contract YAML の精度が大幅に向上します。

### 何をするか

1. Claude が対話でペルソナ・課題・ゴールについて質問する（Diamond 1: 発散→収束）
2. エピック → ユーザーストーリーを構造化する（Diamond 2: 発散→収束）
3. 各ストーリーに受け入れ条件（AC）を EARS-inspired 記法で定義する
4. `.blueprint/requirements/user-stories.md` にマークダウンで出力する
5. Requirements Review Gate で 3 エージェントが要件の一貫性をチェックする

### どう使うか

```bash
/requirements
```

質問に答えていくと、以下が生成されます:

```
.blueprint/requirements/
└── user-stories.md    # ペルソナ・エピック・ユーザーストーリー・AC
```

### いつ使うか

- **新規プロジェクト**: `/blueprint` の最初のステージとして自動実行される
- **要件追加**: 既存の `user-stories.md` がある状態で実行すると差分追加される
- **単独実行**: `/spec` の前に要件を整理したいときに単体で呼び出せる

---

## 3. /spec — 仕様を会話で固める

### なぜあるのか

AI に「○○を作って」と言うと、AI が勝手に仕様を想像して実装してしまいます。結果、「そうじゃない」という手戻りが発生します。

`/spec` は、**実装の前に仕様を構造化された YAML（Contract）に固める**ステージです。Claude が対話で質問を投げかけ、あなたの回答をもとに Contract YAML を生成します。この Contract が後続のテスト・実装・設計書の全てのソースになります。

### 何をするか

1. Claude が技術スタック・アーキテクチャ・機能要件について質問する
2. 回答をもとに `.blueprint/config.yaml`（プロジェクト設定）を生成する（初回のみ）
3. 機能ごとに Contract YAML（`.blueprint/contracts/`）を生成する
4. Contract Review Gate で 3 エージェントが仕様の一貫性をチェックする

### どう使うか

```bash
/spec
```

質問に答えていくと、以下が生成されます:

```
.blueprint/
├── config.yaml               # 技術スタック・アーキテクチャ設定
├── contracts/
│   ├── {entity}-domain.yaml  # ドメインロジック
│   ├── {entity}-repo.yaml    # データアクセス
│   ├── {entity}-api.yaml     # REST API
│   └── {screen}.yaml         # 画面仕様（フロントあり時）
├── concepts/                 # ドメイン概念メモ
└── decisions/                # ADR（設計判断の記録）
```

### Contract タイプ

Contract は I/O 境界の種類ごとに分かれています。「何が入って何が出るか」を明示することで、テストと実装を機械的に導出できるようになります。

| type | subtype | 何を定義するか |
|------|---------|--------------|
| `api` | — | REST エンドポイントの入出力・エラーコード |
| `internal` | `service` | ドメインロジックの引数・戻り値・ビジネスルール |
| `internal` | `repository` | データアクセスのインターフェース |
| `external` | — | 外部 API との接続仕様 |
| `file` | — | ファイル入出力のフォーマット |
| `screen` | `list` / `form` / `detail` / `dashboard` | 画面の props・イベント・表示ロジック |

---

## 4. /test-from-contract — 仕様をテストに変換する

### なぜあるのか

Contract YAML は「仕様書」ですが、それだけでは実装が仕様に従っているかを自動検証できません。
`/test-from-contract` は、Contract を **実行可能なテストコード** に変換します。

テストを2レベルに分けているのは理由があります:

- **Level 1（構造テスト）**: 「この型・インターフェースが存在するか」を検証。実装前でも GREEN になる。つまり、**テストの書き方自体が間違っていないことを、実装なしで確認できる**
- **Level 2（振る舞いテスト）**: 「ビジネスルール通りに動くか」を検証。実装前は RED。**TDD の "Red" に相当し、このテストを GREEN にするのが /implement の仕事**

### 何をするか

1. `.blueprint/contracts/` の全 Contract YAML を読み込む
2. Level 1 テスト（型・構造）と Level 2 テスト（振る舞い）を生成する
3. Level 1 テストが全て GREEN であることを実行確認する
4. Test Review Gate でテスト品質をチェックする

### どう使うか

```bash
/test-from-contract
```

生成物:

```
tests/contracts/
├── helpers/fixtures.ts      # テスト用のサンプルデータ
├── level1/                  # 構造検証（実装前でも GREEN）
│   └── {contract}.test.ts
└── level2/                  # 振る舞い検証（実装前は RED）
    └── {contract}.test.ts
```

テスト実行:

```bash
npm run test:level1   # 構造テストのみ（実装前に確認）
npm run test:level2   # 振る舞いテストのみ（実装後に確認）
npm test              # 全テスト
```

---

## 5. /implement — テストが通る実装を生成する

### なぜあるのか

Level 2 テストが RED の状態は「仕様は決まっているが実装がない」状態です。
`/implement` は、**RED テストを GREEN にすることだけを目的に実装コードを生成する** ステージです。

仕様に書かれていないことは実装しません。これにより「AI が勝手に余計な機能を作る」問題を防ぎます。

### 何をするか

1. Contract の依存関係をトポロジカルソートし、実装順序を決定する
2. 実装計画をユーザーに提示する（**承認が必要**）
3. 依存なし → 依存あり の順に Group 別で実装する
4. 各 Contract の実装後に Level 2 テストが GREEN になることを確認する
5. Refactorer（コンテキスト非共有の独立エージェント）がコード品質をチェックする
6. Code Review Gate（4 エージェント）で Contract との乖離を検出する
7. 実装完了をユーザーに報告する（**承認が必要**）

### どう使うか

```bash
/implement
```

生成されるディレクトリ構造は `/spec` で選んだアーキテクチャパターンに依存します（→ [9. アーキテクチャパターン](#9-アーキテクチャパターン)）。

`screen` タイプの Contract がある場合、フロントエンド（Vite + React）も自動生成されます:
- `index.html` / `src/main.tsx` — エントリーポイント
- `src/App.tsx` — ルーティング + API 接続
- コンポーネントは Props-based design（テストしやすい構造）

---

## 6. /generate-docs — コードから設計書を後追い生成する

### なぜあるのか

先に設計書を書いてから実装すると、実装中に仕様が変わって設計書が陳腐化します。
blueprint-plugin では **実装が完了してから設計書を生成する** ことで、「コードと設計書の乖離」を構造的に防ぎます。

設計書のソースは Contract YAML + 実装コードなので、常にコードの実態と一致します。

### 何をするか

1. `.blueprint/contracts/` と実装コードを読み込む
2. `docs/` に設計書を生成する
3. Doc Review Gate でドキュメント品質をチェックする

### どう使うか

```bash
/generate-docs
```

生成物:

```
docs/
├── overview.md             # システム概要・アーキテクチャ図・起動方法
├── domain-model.md         # ドメインモデル・ビジネスルール詳細
├── api-reference.md        # REST API 全エンドポイント仕様
├── data-model.md           # DB スキーマ・ER 図
├── frontend-architecture.md # コンポーネント構成（フロントあり時）
└── traceability.md         # Contract → テスト → 実装の対応表
```

---

## 7. Review Gate — AI の出力を AI がレビューする

### なぜあるのか

AI が生成したコード・テスト・仕様を、同じ AI が「いいね」と言っても信頼性がありません。
Review Gate は **複数の独立エージェント**（3〜4体）が並列でレビューすることで、単一 AI の盲点を補います。

Gate があることで、仕様の抜け・テストの不足・実装の乖離が次のステージに伝播する前に検出されます。

### 仕組み

| Gate | タイミング | エージェント数 | 検証内容 |
|------|-----------|-------------|---------|
| Requirements Gate | /requirements の後 | 3 | ペルソナ・ストーリー・AC の一貫性・網羅性 |
| Contract Gate | /spec の後 | 3 | Contract 間の整合性・メタデータ・型定義 |
| Test Gate | /test-from-contract の後 | 3 | テストカバレッジ・Contract との一致 |
| Code Gate | /implement の後 | 4 | 実装と Contract の乖離・コード品質 |
| Doc Gate | /generate-docs の後 | 3 | ドキュメントの正確性・網羅性 |

### Severity（深刻度）

| レベル | 意味 | Gate への影響 |
|--------|------|-------------|
| **P0** | 致命的（仕様違反・バグ） | 1件でも → REVISE |
| **P1** | 重要（乖離・警告） | 2件以上 → REVISE |
| **P2** | 軽微（改善提案） | Gate に影響しない |

### REVISE になったら

```
Gate が REVISE を返す
  → 自動修正サイクル（最大 3 回）
  → 3 回後も REVISE → ユーザーに報告して相談
```

### Finding を却下・延期する（disposition）

レビュー指摘が誤検出や意図的な設計の場合は、disposition を付けて処理できます:

| disposition | いつ使うか |
|-------------|-----------|
| `false_positive` | 指摘自体が間違っている |
| `wont_fix` | 意図的にそうしている（既知の制限） |
| `downgraded` | P0 → P1 等に降格したい（理由を添える） |
| `deferred` | 今は対応しない。別ステージに繰越（Gate カウント除外） |

---

## 8. /blueprint-improve — 使用ログから改善案を生成する

### なぜあるのか

blueprint-plugin を使い続けると、**パターン** が見えてきます:

- 「Gate でいつも `missing_constraint` が指摘される」→ テンプレートに制約例を追加すべき
- 「/implement で毎回同じツールエラーが出る」→ エラーハンドリングの改善が必要
- 「ユーザーが毎回 /spec の出力を手修正している」→ /spec の質問やテンプレートに問題がある

人間がこれを目視で振り返るのは現実的ではありません。`/blueprint-improve` は、蓄積されたログからこれらのパターンを自動検出し、具体的な改善案を PR として提案します。

### 全体像

```
あなたが普段通りパイプラインを使う
        ↓
SessionEnd Hook が透過的にログを収集（自動・設定不要）
  └─ 何を収集: Gate findings, エラー, ユーザー修正, セッション統計
  └─ 保存先:   ~/.claude/blueprint-logs/bl-YYYYMMDD-NNN.yaml
        ↓
ログが蓄積（10 件以上で起動時に通知）
        ↓
/blueprint-improve を実行
  └─ 統計レポート → パターン検出 → 改善案提示 → ユーザー承認 → PR 作成
```

### 収集されるデータと理由

| データ | ソース | なぜ収集するか |
|--------|--------|--------------|
| Gate findings | pipeline-state.yaml | 「どの category の指摘が繰り返されるか」を知るため |
| エラーパターン | transcript | 「どのツールがどのフェーズで失敗しやすいか」を知るため |
| ユーザー修正 | transcript | 「ユーザーが手動で直す＝AI の出力品質が低い箇所」を特定するため |
| セッション統計 | transcript | パイプラインの効率（ツール使用数、コード変更数）を計測するため |

### どう使うか

#### 統計だけ見たいとき

```bash
/blueprint-improve --stats
```

何件のログがあり、Gate findings・エラー・ユーザー修正がどう分布しているかを確認できます。PR は作成しません。

出力例:

```yaml
summary:
  log_count: 15
  log_range:
    from: "bl-20260301-001"
    to: "bl-20260310-003"
  pipeline_results:
    completed: 12
    partial: 2
    failed: 1
  gate_findings:
    total_p0: 0
    total_p1: 12
    total_p2: 34
  errors:
    total: 3
  user_corrections:
    total: 5
```

#### 改善 PR を作成したいとき

```bash
/blueprint-improve
```

1. 統計レポートを生成し、全体像を把握する
2. パターンを検出する（例: `missing_constraint` が 5 回出現 → high priority）
3. 改善案を一覧で提示する（対象ファイル・根拠・優先度付き）
4. **あなたが採用/棄却を選ぶ**（勝手に PR は作らない）
5. 承認された改善を適用し、`sizukutamago/blueprint-plugin` に PR を作成する
6. 分析済みログのステータスを更新する（再分析を防止）

#### 古いログを掃除したいとき

```bash
/blueprint-improve --cleanup
```

90 日（TTL）を超過したログを一覧表示し、確認後に削除します。分析済みのログは TTL に関わらず保持されます。

### プライバシー

| 項目 | 内容 |
|------|------|
| **保存先** | ローカルのみ（`~/.claude/blueprint-logs/`） |
| **外部送信** | 一切なし |
| **保持期間** | 90 日（`--cleanup` で期限切れを削除） |
| **収集停止** | ログの `privacy.opt_out: true` を設定 |
| **手動削除** | `rm ~/.claude/blueprint-logs/bl-*.yaml` でいつでも削除可能 |

---

## 9. Contract YAML の書き方

### api タイプ — REST エンドポイントを定義する

「何を受け取って何を返すか」と「どんなエラーがありうるか」を宣言します。これが /test-from-contract でテストに、/implement で実装コードになります。

```yaml
id: CON-book-api
type: api
name: Book API
version: 1.0.0
depends_on:
  - CON-book-domain

endpoints:
  - method: POST
    path: /api/v1/books
    input:
      body:
        title:
          type: string
          required: true
          min: 1
          max: 200
        status:
          type: string
          enum: [want_to_read, reading, read]
          required: true
    output:
      status: 201
      body:
        id:
          type: string
    errors:
      - status: 400
        code: VALIDATION_ERROR
      - status: 409
        code: DUPLICATE_ERROR

business_rules:
  - id: BR-001
    rule: rating は status が read の場合のみ設定可能
```

### screen タイプ — 画面の振る舞いを定義する

画面が受け取る props・発火するイベント・表示ロジックを宣言します。Props-based design なので、テスト容易な構造が強制されます。

```yaml
id: CON-book-list-screen
type: screen
screen_type: list
name: 本一覧画面
depends_on:
  - CON-book-api

components:
  - id: BookListPage
    props:
      onFetch:
        type: function
        required: true
      onDelete:
        type: function
        required: true

events:
  - name: onDelete
    trigger: 削除ボタンクリック
    action: confirm → DELETE /api/v1/books/:id → 一覧更新
```

---

## 10. アーキテクチャパターン

`/spec` の対話中にアーキテクチャを選択します。選択に迷ったら layered を選んでください。

### layered（推奨・中規模）

最もバランスが良く、多くのプロジェクトに適合します。層の境界が明確なので、後から clean に移行することも容易です。

```
src/
├── domain/           # エンティティ・ビジネスルール（外部依存なし）
├── infrastructure/   # DB・外部 API 実装
├── application/      # ユースケース
└── presentation/     # HTTP ルーター
```

### clean（大規模・長期運用）

依存関係の逆転（Dependency Inversion）を徹底。テストしやすく変更に強いが、層が多いためコード量が増えます。

```
src/
├── domain/           # Entity, Value Object, Repository Interface
├── usecase/          # Application Business Rules
├── interface/        # Controller, Presenter, Gateway Interface
└── infrastructure/   # DB, External API, Framework
```

### flat（プロトタイプ・小規模）

最小構造。PoC や小さな API を素早く作りたいときに。規模が大きくなったら layered に移行推奨。

```
src/
├── routes/
├── models/
└── services/
```

後から変更する場合: `.blueprint/config.yaml` の `architecture` を書き換えて `/implement` を再実行。

---

## 11. 既存プロジェクトへの適用

既存コードベース（brownfield）に blueprint を適用する場合は、まず `/gap-analysis` で現状を分析してから Contract を作成します。

```bash
/gap-analysis        # 既存コードを分析し、課題と改善点を抽出する
/spec                # 分析結果をもとに Contract を生成する
/test-from-contract  # テストを生成する（既存テストとの整合を確認）
/implement           # 差分のみ実装する
```

---

## 12. トラブルシューティング

### Contract Review Gate が通らない

**原因**: Contract YAML のフォーマットや型指定が不正。

```
対処:
1. Gate の findings を確認し、どの Contract のどのフィールドが問題か特定する
2. P0 指摘は自動修正されるが、繰り返す場合は手動で修正する
3. よくある原因:
   - type: domain → 無効。type: internal + subtype: service が正しい
   - depends_on の参照先が存在しない
   - required フィールドに型指定がない
```

### Level 2 テストが RED のまま

**前提**: Level 2 テストは実装前は RED が正常です。

```
実装後も RED の場合:
1. npm run test:level2 2>&1 | head -50 でエラーを確認
2. インポートパスが間違っている → tests/contracts/level2/ を修正
3. ビジネスルールの実装が足りない → src/domain/ を確認
4. テスト自体が Contract と乖離している → /test-from-contract を再実行
```

### /blueprint-improve でログが 0 件

**原因**: SessionEnd Hook は **セッション終了時** にログを収集します。実行中のセッションではまだ収集されていません。

```
対処:
1. Claude Code を一度終了して再起動する
2. ls ~/.claude/blueprint-logs/ でログファイルが存在するか確認
3. Hook が登録されているか確認:
   cat ~/.claude/plugins/*/hooks/hooks.json 2>/dev/null | grep SessionEnd
```

### プラグインのキャッシュが古い

```bash
# 方法 1: キャッシュをバイパスしてローカル読み込み
claude --plugin-dir /path/to/blueprint-plugin

# 方法 2: キャッシュクリア + アップデート
./scripts/plugin-update.sh
```

### コンテキスト不足でパイプラインが止まる

**原因**: 複雑なプロジェクトではコンテキストウィンドウが足りなくなることがあります。

```bash
/context-compressor      # 設計書・Contract を要約してトークンを節約
/blueprint --resume      # 最後に完了した Stage から再開
```
