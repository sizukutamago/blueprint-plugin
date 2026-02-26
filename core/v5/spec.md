# Spec Workflow

Contract YAML をブレインストーミングから生成するワークフロー。
ユーザーがビジネス判断、AI が構造化を担当する。

> **前提**: `knowledge-structure.md` と `contract-schema.md` を参照。

## ワークフロー（7 ステップ）

### Step 1: コンテキスト読み込み

`.knowledge/` ディレクトリの状態を確認する。

- **存在しない場合**: ディレクトリ構造を初期化（`knowledge-structure.md` の構造に従う）
- **存在する場合**: 既存の contracts, concepts, decisions を読み込んで現状を把握

```
チェック項目:
- .knowledge/ の存在
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
```

**タイプ判定基準**:
- 自社が HTTP エンドポイントを公開する → `api`
- 他社 API を呼び出す → `external`
- ファイルの入出力 → `file`

ユーザーの承認を得てから次へ進む。

### Step 5: Contract YAML 生成

承認された Contract 一覧に基づき、テンプレートを使って YAML を生成する。

```
生成手順:
1. タイプに対応するテンプレートを読み込む
2. ブレスト結果から各フィールドを埋める
3. links の depends_on / impacts を設定
4. business_rules / constraints / processing_rules を設定
5. ファイルに書き出す
```

**配置先**:
- `api` → `.knowledge/contracts/api/{name}.contract.yaml`
- `external` → `.knowledge/contracts/external/{name}.contract.yaml`
- `file` → `.knowledge/contracts/files/{name}.contract.yaml`

**SemVer 初期値**: `1.0.0`（新規の場合）

### Step 6: 副産物生成

ブレスト中に出たドメイン知識と設計判断を `.knowledge/` に書き出す。

**concepts/**:
- ブレストで登場した主要ドメイン概念ごとに 1 ファイル
- frontmatter: `id`, `links`
- 本文: 概念の説明、構成要素、ビジネス上の注意、相互リンク `[[]]`

**decisions/**:
- ブレストで判断した技術選択・設計方針ごとに 1 ファイル
- ADR 形式: Context / Decision / Reason / Alternatives Considered / Consequences
- frontmatter: `id`, `status: accepted`, `date`, `links`

> concepts/decisions はブレスト中に自然に出てくるもの。「何を作るか」ではなく「なぜそうするか」の記録。

### Step 7: サマリー出力

生成結果をまとめて次のアクションを提示する。

```
## 生成ファイル
- .knowledge/contracts/api/{name}.contract.yaml (CON-{name} v1.0.0)
- .knowledge/concepts/{concept}.md
- .knowledge/decisions/DEC-{NNN}-{name}.md
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
| .knowledge/ 初期化失敗 | git root でない場合の案内、権限確認 |
| ブレストが収束しない | 10 質問上限 + open_questions への退避 |
| タイプ判定が曖昧 | ユーザーに判断を委ねる |
| 既存 Contract との依存が不明確 | 明示的に確認、不明な場合は TODO リンクとして残す |
