# Contract YAML Schema

Contract は I/O 境界（API、外部連携、ファイル）の機械可読な仕様。
テスト自動生成の入力として使われる。

## 共通メタデータ（全タイプ必須）

```yaml
id: CON-{name}                    # 一意識別子
type: api | external | file       # I/O タイプ
version: "1.0.0"                  # SemVer
status: draft | active | deprecated
owner: "@handle"                  # 責任者
updated_at: "YYYY-MM-DD"          # 最終更新日

links:
  implements: [FR-xxx]            # どの要件を実装するか
  depends_on: [CON-xxx]           # 依存先 Contract
  decided_by: [DEC-xxx]           # 関連する設計判断
  impacts: [CON-xxx]              # 影響を与える先
```

## タイプ別スキーマ

### api — 自社が公開する API

自社サービスが外部に公開するエンドポイントの仕様。

```yaml
# API 定義
method: GET | POST | PUT | PATCH | DELETE
path: "/api/..."

input:
  content_type: application/json
  body:
    {field_name}:
      type: string | integer | number | boolean | array | object
      required: true | false
      min: N                    # 数値の最小値
      max: N                    # 数値の最大値
      min_items: N              # 配列の最小要素数
      pattern: "regex"          # 文字列のパターン
      enum: [a, b, c]           # 許容値
      # object の場合
      properties:
        {sub_field}: { type: ..., ... }
      # array の場合
      items:
        {sub_field}: { type: ..., ... }

output:
  success:
    status: 201                 # HTTP ステータスコード
    body:
      {field_name}: { type: ..., format: ..., description: "..." }
  errors:
    - status: 400
      code: error_code
      description: "エラーの説明"
      body: { ... }             # オプション: エラー固有のボディ

business_rules:
  - id: BR-{NNN}
    rule: "ルールの説明"

# オプション
state_transition:
  entity: {entity_name}
  initial: {initial_state}
  transitions:
    {state}: [{next_state}, ...]
```

**テスト導出ポイント**:
- `required: true` → 空値テスト
- `min`/`max` → 境界値テスト (N-1, N, N+1)
- `pattern` → マッチ/不一致テスト
- `enum` → 無効値テスト + 全有効値テスト
- `business_rules` → 各ルール ID ごとに正常系 + 異常系
- `state_transition` → 初期状態、許可遷移、拒否遷移
- `errors` → 各エラーコードのレスポンス形式

### external — 外部 API を呼ぶ側

他社サービスの API を呼び出す仕様。

```yaml
# 外部 API 情報
provider: "サービス名"
api_version: "バージョン"        # オプション
docs_url: "ドキュメント URL"     # オプション

endpoint:
  method: POST
  url: "https://..."

# 自分が送るリクエスト
request:
  auth: "Bearer xxx"             # 認証方式
  body:
    {field_name}:
      type: string | integer | ...
      required: true | false
      value: "fixed_value"       # 固定値の場合
      description: "説明"

# 相手が返すレスポンス
response:
  success:
    status: 200
    body:
      {field_name}: { type: ..., pattern: "...", enum: [...] }
  errors:
    - type: error_type
      description: "エラーの説明"
      handling: "対処方法"

# 自分側の制約
constraints:
  - id: EC-{NNN}
    rule: "制約の説明"
```

**テスト導出ポイント**:
- `request.body` のフィールド → リクエスト構築の検証
- `response.errors` → 各エラータイプのハンドリング検証
- `constraints` → 冪等性、タイムアウト、リトライ等の制約検証

### file — ファイル連携

CSV/バッチ等のファイルベース I/O の仕様。

```yaml
# ファイル定義
direction: import | export
format: csv | tsv | json | xml
encoding: utf-8
delimiter: ","                   # CSV/TSV の場合
has_header: true | false
max_file_size: "10MB"            # オプション
max_rows: 10000                  # オプション

columns:
  - name: column_name
    type: string | integer | number | boolean
    required: true | false
    description: "説明"
    pattern: "regex"             # オプション
    min: N                       # オプション
    max: N                       # オプション
    max_length: N                # オプション
    enum: [a, b, c]              # オプション
    default: "value"             # オプション

processing_rules:
  - id: PR-{NNN}
    rule: "処理ルールの説明"

result:
  success:
    body:
      {field_name}: { type: ... }
  error:
    body:
      failed_rows:
        type: array
        items:
          row_number: { type: integer }
          column: { type: string }
          error: { type: string }

example: |                       # オプション: サンプルデータ
  header1,header2,...
  value1,value2,...
```

**テスト導出ポイント**:
- `columns` の `required`/`min`/`max`/`max_length`/`pattern`/`enum`/`default` → 各カラムの検証テスト
- `max_rows` → 上限テスト
- `has_header` → ヘッダー有無テスト
- `processing_rules` → 各ルール ID ごとに正常系 + 異常系
- `result.error` → エラーレスポンス形式

## テスト導出パターン一覧

Contract のフィールドからテストを機械的に導出する:

| フィールド | 生成するテスト |
|-----------|--------------|
| `required: true` | 空値/未送信 → エラー |
| `min: N` | N-1 → エラー、N → OK（境界値） |
| `max: N` | N+1 → エラー、N → OK（境界値） |
| `max_length: N` | N+1 文字 → エラー、N 文字 → OK |
| `pattern: "^...$"` | 不一致値 → エラー、境界長 |
| `enum: [a, b, c]` | 無効値 → エラー、全有効値 → OK |
| `default: X` | 省略時 → X が適用される |
| `business_rules[]` | 各ルール ID ごとに正常系 + 異常系 |
| `constraints[]` | 各制約 ID ごとに検証 |
| `state_transition` | 初期状態、許可遷移、拒否遷移 |
| `errors[]` | 各エラーコードのレスポンス形式 |

> **制約干渉に注意**: テスト生成時、他の制約（例: `max: 99`）を超えない値を使う。
> 例: 在庫不足テストで `quantity: 99999` は `max: 99` に先に引っかかる → `quantity: 10`（有効範囲内）で低在庫商品を使う。
