# Phase: Database

データ構造・エンティティ定義フェーズ。
TypeScript 型定義、エンティティ設計、バリデーションルール、物理 DB 設計を作成する。

## Contract (YAML)

```yaml
phase_id: "4"
required_artifacts:
  - docs/requirements/user-stories.md
  - docs/requirements/context_unified.md   # optional

outputs:
  - path: docs/04_data_structure/data_structure.md
    required: true

contract_outputs:
  - key: decisions.entities
    type: array
    description: "エンティティ一覧（id, name, attributes, physical）"
  - key: traceability.fr_to_ent
    type: object
    description: "FR-ID → ENT-ID[] のマッピング"

quality_gates:
  - "全 FR-ID が最低1つのエンティティにマッピングされていること"
  - "全エンティティに ENT-ID が付与されていること"
  - "PII 分類フィールドにはデータ保護方針が定義されていること"
  - "物理設計（テーブル、インデックス、制約、容量見積もり）が定義されていること"
```

## 入力要件

| 入力 | 必須 | 説明 |
|------|------|------|
| docs/requirements/user-stories.md | ○ | エンティティ抽出元（Gherkin 形式） |
| docs/requirements/context_unified.md | △ | 用語・コンテキスト情報 |

## 出力ファイル

| ファイル | 説明 |
|---------|------|
| docs/04_data_structure/data_structure.md | エンティティ定義（型定義 + 物理設計） |

### data_structure.md 必須セクション

1. 命名規則
2. エンティティ定義（型定義 + フィールド詳細 + データ分類）
3. フロントエンド専用型（Form, State）
4. バリデーションルール
5. 物理データベース設計（テーブル定義、インデックス、制約、容量見積もり）
6. データ暗号化方式
7. マイグレーション戦略

## ワークフロー

```
1. 機能要件（user-stories.md）を読み込み
2. 要件からエンティティを抽出
3. エンティティ間の関係を分析
4. 各エンティティに ENT-ID を付与
5. TypeScript 型定義を生成
6. フィールド詳細を定義（データ分類を含む）
7. 派生型を定義（Form, State, Extended）
8. 物理 DB 設計（テーブル定義、インデックス、制約、容量見積もり）
9. データ暗号化方式とマイグレーション戦略を定義
10. FR → ENT トレーサビリティを記録
11. contract_outputs を出力
```

**重要**: このフェーズは API 設計より前に実行する。
エンティティは API の入出力の基盤となる。

## ID 採番ルール

| 項目 | ルール |
|------|--------|
| 形式 | ENT-{EntityName}（PascalCase） |
| 例 | ENT-User, ENT-Product |

## 命名規則

| 対象 | 規則 |
|------|------|
| 型名 | PascalCase |
| プロパティ | camelCase |
| 定数 | UPPER_SNAKE_CASE |
| ブール型 | is/has/can + Name |

## 型定義の接尾辞

| 接尾辞 | 用途 |
|--------|------|
| (なし) | 基本エンティティ |
| Extended | 関連含む拡張版 |
| Form | フォーム入力用 |
| State | UI 状態管理用 |

## エンティティ定義テンプレート

### 型定義

```typescript
interface {{EntityName}} {
  id: string;
  // ... フィールド
  createdAt: string;
  updatedAt: string;
}
```

### フィールド詳細テーブル

| フィールド | 型 | 必須 | データ分類 | 説明 | 制約 |
|-----------|-----|------|-----------|------|------|
| id | string | ○ | Internal | ID | UUID 形式 |
| email | string | ○ | PII | メール | RFC 5322 |

### データ分類（IPA 準拠）

| 分類 | 説明 | 取り扱い |
|------|------|---------|
| PII | 個人を識別可能な情報（氏名、メール、住所等） | 暗号化保存、アクセスログ必須、保持期限設定 |
| Sensitive | 機密業務情報（決済、医療等） | 暗号化保存、アクセス制限 |
| Internal | システム内部情報（ID、タイムスタンプ等） | 標準的なアクセス制御 |
| Public | 公開情報（カテゴリ名等） | 制限なし |

## 物理データベース設計

### テーブル定義テンプレート

| カラム名 | データ型 | NULL | デフォルト | 制約 | 説明 |
|---------|---------|------|-----------|------|------|
| id | UUID | NO | gen_random_uuid() | PK | 主キー |

### インデックス設計テンプレート

| テーブル | インデックス名 | カラム | 種別 | 用途 |
|---------|--------------|--------|------|------|
| users | idx_users_email | email | BTREE UNIQUE | メール検索 |

### 制約定義テンプレート

| テーブル | 制約名 | 種別 | カラム | 参照先 |
|---------|--------|------|--------|--------|
| posts | fk_posts_author | FK | author_id | users(id) |

### 容量見積もりテンプレート

| テーブル | 初期レコード数 | 年間増加率 | 1年後予測 | 3年後予測 | 平均行サイズ |
|---------|--------------|-----------|----------|----------|------------|

### データ暗号化テンプレート

| 対象 | 方式 | 鍵管理 |
|------|------|--------|
| 保存時暗号化 | AES-256 | KMS |
| 転送時暗号化 | TLS 1.3 | 自動 |
| カラムレベル暗号化 | (PII フィールドのみ) | KMS |

### マイグレーション戦略テンプレート

| 項目 | 内容 |
|------|------|
| DDL 管理ツール | (プロジェクトに応じて選定) |
| バージョン管理 | (連番 or タイムスタンプ) |
| ロールバック方針 | (down マイグレーション必須等) |

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| 要件不在（FR が見つからない） | P0 報告、web-requirements への差し戻しを要請 |
| エンティティ抽出不可 | 入力要請、ユーザーに主要データを質問 |
| 循環参照検出 | P2 報告、設計見直しを提案 |
| FR 対応漏れ | P1 報告、該当 FR を open_questions に記録 |
