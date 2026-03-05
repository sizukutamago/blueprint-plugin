# blueprint-plugin 詳細ガイド

## 目次

- [パイプライン概要](#パイプライン概要)
- [Stage 1: /spec — Contract 生成](#stage-1-spec--contract-生成)
- [Stage 2: /test-from-contract — テスト生成](#stage-2-test-from-contract--テスト生成)
- [Stage 3: /implement — 実装生成](#stage-3-implement--実装生成)
- [Stage 4: /generate-docs — 設計書生成](#stage-4-generate-docs--設計書生成)
- [Contract YAML の構造](#contract-yaml-の構造)
- [Review Gate（品質チェック）](#review-gate品質チェック)
- [アーキテクチャパターン選択](#アーキテクチャパターン選択)
- [既存プロジェクト（brownfield）への適用](#既存プロジェクトbrownfieldへの適用)
- [トラブルシューティング](#トラブルシューティング)

---

## パイプライン概要

```
Stage 1  /spec              ブレスト → Contract YAML
            ↓
        [Contract Review Gate]  3 エージェント並列レビュー
            ↓
Stage 2  /test-from-contract  Contract → Level 1/2 テスト
            ↓
        [Test Review Gate]
            ↓
Stage 3  /implement          RED テスト → 実装コード
            ↓
        [Code Review Gate]    4 エージェント並列レビュー
            ↓
Stage 4  /generate-docs       コード → 設計書
            ↓
        [Doc Review Gate]
```

各 Gate の判定基準: **P0=0 かつ P1≤1 → PASS**（最大 3 サイクル自動修正）

---

## Stage 1: /spec — Contract 生成

### 何をするか

- Claude が質問（技術スタック・アーキテクチャ・機能要件）を投げかける
- 回答を元に `.blueprint/config.yaml` と Contract YAML を生成する
- Contract Review Gate で 3 エージェントが仕様の一貫性をチェック

### 生成物

```
.blueprint/
├── config.yaml               # 技術スタック・アーキテクチャ設定
├── contracts/
│   ├── {entity}-domain.yaml  # ドメインロジック（type: internal/service）
│   ├── {entity}-repo.yaml    # データアクセス（type: internal/repository）
│   ├── {entity}-api.yaml     # REST API（type: api）
│   └── {screen}.yaml         # 画面仕様（type: screen）  ← フロントあり時
├── concepts/                 # ドメイン概念メモ
└── decisions/                # ADR（アーキテクチャ決定記録）
```

### Contract タイプ

| type | subtype | 用途 |
|------|---------|------|
| `api` | — | REST/HTTP エンドポイント |
| `internal` | `service` | ドメインロジック・ユースケース |
| `internal` | `repository` | データアクセス境界 |
| `external` | — | 外部 API クライアント |
| `file` | — | ファイル入出力 |
| `screen` | `list` / `form` / `detail` / `dashboard` | 画面コンポーネント |

### 途中で止まった場合

```bash
/blueprint --resume  # 最後に完了した Stage から再開
```

---

## Stage 2: /test-from-contract — テスト生成

### 2レベルのテスト

**Level 1 — 構造検証（即 GREEN）**
- Contract で宣言した型・インターフェース・列挙値の存在を確認
- 実装前でも全て PASS する
- 「この型定義が合意されているか」の仕様確認テスト

**Level 2 — 実装検証（RED stubs）**
- Contract の振る舞い（ビジネスルール・エラーコード・HTTP ステータス）を検証
- 実装前は import エラーで RED → 実装後に GREEN
- TDD の「テストが仕様書」として機能する

### 生成物

```
tests/contracts/
├── helpers/fixtures.ts      # テスト用型定義・サンプルデータ
├── level1/                  # 構造検証（即 GREEN）
│   ├── {contract}.test.ts
│   └── ...
└── level2/                  # 実装検証（RED → 実装後 GREEN）
    ├── {contract}.test.ts
    └── ...
```

### テスト実行

```bash
npm run test:level1   # Level 1 のみ（実装前の確認）
npm run test:level2   # Level 2 のみ（実装後の確認）
npm test              # 全テスト
```

---

## Stage 3: /implement — 実装生成

### 実行フロー

1. **実装計画提示（承認必要）** — トポロジカルソートで実装順序を決定
2. **Group 別実装** — 依存なし → 依存あり の順に実装
3. **Level 2 テスト GREEN 確認** — 各 Contract の実装後にテスト実行
4. **Refactorer** — コンテキスト非共有の独立エージェントがコード品質をチェック
5. **Code Review Gate** — 4 エージェントが Contract との乖離を検出

### アーキテクチャパターン

`/spec` で選択したパターンに応じた構造が生成される:

**layered（推奨・中規模 API 向け）**
```
src/
├── domain/           # エンティティ・ビジネスルール（依存なし）
├── infrastructure/   # DB・外部API実装
├── application/      # ユースケース
└── presentation/     # HTTP ルーター
```

**clean（大規模・長期運用向け）**
```
src/
├── domain/           # Entity, Value Object, Repository Interface
├── usecase/          # Application Business Rules
├── interface/        # Controller, Presenter, Gateway Interface
└── infrastructure/   # DB, External API, Framework
```

**flat（プロトタイプ・小規模向け）**
```
src/
├── routes/
├── models/
└── services/
```

### フロントエンドが含まれる場合

`screen` タイプの Contract がある場合、Integrator が自動生成:
- `index.html` / `src/main.tsx` — Vite エントリーポイント
- `src/App.tsx` — ルーティング + fetch wiring（コンテナパターン）

コンポーネントは **Props-based design** で生成されるため、`@testing-library/react` テストとの両立が可能。

---

## Stage 4: /generate-docs — 設計書生成

実装コードから設計書を**後追い生成**する。仕様先行（/spec → /implement）で作ると、コードと設計書の乖離が起きにくい。

### 生成物

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

## Contract YAML の構造

### api タイプの例

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

### screen タイプの例

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

## Review Gate（品質チェック）

### Severity レベル

| レベル | 意味 | Gate への影響 |
|--------|------|--------------|
| P0 | 致命的な仕様違反・バグ | 1件でも → REVISE（ブロック） |
| P1 | 重要な乖離・警告 | 2件以上 → REVISE |
| P2 | 軽微な改善提案 | Gate に影響しない |

### Gate を通過できない場合

```
[REVISE] P0: 1件, P1: 2件
→ 自動修正サイクル（最大3回）
→ 3回後も REVISE → ユーザーに報告・相談
```

### Finding の disposition（却下・延期）

| disposition | 意味 |
|-------------|------|
| `false_positive` | 誤検出として却下 |
| `wont_fix` | 既知の制限として受け入れ |
| `downgraded` | P0 → P1 等に降格（理由必須） |
| `deferred` | 別ステージに繰越（Gate カウント除外） |

---

## アーキテクチャパターン選択

| パターン | 向いている規模 | 特徴 |
|---------|--------------|------|
| `layered` | 中規模（推奨） | 3層。理解しやすく変更しやすい |
| `clean` | 大規模・長期 | 4層。依存関係の逆転でテスト容易 |
| `flat` | 小規模・PoC | 最小構造。素早く立ち上げられる |

`/spec` 実行時にアーキテクチャを選択する。後から変更する場合は `config.yaml` を直接編集して `/implement` を再実行。

---

## 既存プロジェクト（brownfield）への適用

`/gap-analysis` スキルを使い、既存コードベースを分析してから Contract を作成する:

```
1. /gap-analysis        # 既存コードの分析・課題抽出
2. /spec                # 分析結果を元に Contract 生成
3. /test-from-contract  # テスト生成（既存テストとの整合を確認）
4. /implement           # 差分のみ実装
```

---

## トラブルシューティング

### Contract Review Gate が通らない

```yaml
# findings を確認してどの Contract のどのフィールドに問題があるか特定
# P0 の場合は自動修正されるが、繰り返す場合は Contract を手動で修正

# 例: type が無効な場合
type: domain  # ← 無効
type: internal  # ← 正しい（subtype: service を追加）
subtype: service
```

### Level 2 テストが RED のまま

Level 2 テストは実装前は RED が正常。実装後も RED の場合:

```bash
# エラーを確認
npm run test:level2 2>&1 | head -50

# インポートパスが間違っている場合は tests/contracts/level2/ を修正
# ビジネスルールの実装が足りない場合は src/domain/ を確認
```

### プラグインのキャッシュが古い

```bash
# キャッシュを使わずローカルのプラグインを直接読む
claude --plugin-dir /path/to/blueprint-plugin

# またはキャッシュをクリアしてアップデート
./scripts/plugin-update.sh
```

### コンテキスト不足でパイプラインが止まる

複雑なプロジェクトでは `/context-compressor` を使ってコンテキストを圧縮:

```bash
/context-compressor  # 設計書・Contract を要約してコンテキストを節約
```

その後、`/blueprint --resume` で再開。
