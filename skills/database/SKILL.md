---
name: database
description: This skill should be used when the user asks to "design data model", "create entity definitions", "define TypeScript types", "design database schema", "create data structure", or "model entities". Defines data structures and entity models with TypeScript type definitions for Wave A parallel execution.
version: 2.1.0
model: sonnet
---

# Database Skill

データ構造・エンティティを定義するスキル。
TypeScript型定義、エンティティ設計、バリデーションルールの作成に使用する。

**実行タイミング**: Wave A（architecture-skeleton, design-inventory と並列）

## 前提条件

| 条件 | 必須 | 説明 |
|------|------|------|
| docs/requirements/user-stories.md | ○ | エンティティ抽出元（web-requirements 出力） |
| docs/requirements/context_unified.md | △ | 用語・コンテキスト情報 |

## 出力ファイル

| ファイル | テンプレート | 説明 |
|---------|-------------|------|
| docs/04_data_structure/data_structure.md | {baseDir}/references/data_structure.md | エンティティ定義 |

## 依存関係

| 種別 | 対象 |
|------|------|
| 前提スキル | web-requirements |
| 並列スキル | architecture-skeleton, design-inventory（Wave A） |
| 後続スキル | api（Wave B）, wave-aggregator |

## Wave A 契約出力

Blackboard に以下を登録する:

```yaml
contract_outputs:
  - key: decisions.entities
    value:
      - id: ENT-User
        name: User
        attributes: [id, email, name, role, created_at, updated_at]
      - id: ENT-Post
        name: Post
        attributes: [id, title, content, author_id, status, published_at]
```

## ID採番ルール

| 項目 | ルール |
|------|--------|
| 形式 | ENT-{EntityName}（PascalCase） |
| 例 | ENT-User, ENT-Product |

## ワークフロー

```
1. 機能要件を読み込み
2. 要件からエンティティを抽出
3. エンティティ間の関係を分析
4. 各エンティティにENT-IDを付与
5. TypeScript型定義を生成
6. フィールド詳細を定義（データ分類を含む）
7. 派生型を定義
8. 物理DB設計（テーブル定義、インデックス、制約、容量見積もり）
9. データ暗号化方式とマイグレーション戦略を定義
```

**重要**: このフェーズはAPI設計より前に実行する。
エンティティはAPIの入出力の基盤となる。

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
| State | UI状態管理用 |

## エンティティ定義例

```typescript
interface User {
  id: string;
  email: string;
  name: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}
```

## フィールド詳細

| フィールド | 型 | 必須 | 説明 | 制約 | データ分類 |
|-----------|-----|------|------|------|-----------|
| id | string | ○ | ID | UUID形式 | Internal |
| email | string | ○ | メール | RFC 5322 | PII |

### データ分類（IPA準拠）

| 分類 | 説明 | 取り扱い |
|------|------|---------|
| PII | 個人を識別可能な情報（氏名、メール、住所等） | 暗号化保存、アクセスログ必須、保持期限設定 |
| Sensitive | 機密業務情報（決済、医療等） | 暗号化保存、アクセス制限 |
| Internal | システム内部情報（ID、タイムスタンプ等） | 標準的なアクセス制御 |
| Public | 公開情報（カテゴリ名等） | 制限なし |

## SendMessage 完了報告

タスク完了時に以下の YAML 形式で Lead に SendMessage を送信する:

```yaml
status: ok | needs_input
severity: null
artifacts:
  - docs/04_data_structure/data_structure.md
contract_outputs:
  - key: decisions.entities
    value:
      - id: ENT-User
        name: User
        attributes: [id, email, name, role, ...]
        physical:
          table_name: users
          indexes: [idx_users_email]
          estimated_rows: 10000
          data_classification: [PII, Internal]
      # 全エンティティを列挙（physical 含む）
  - key: traceability.fr_to_ent
    value:
      FR-001: [ENT-User]
      # FR → ENT マッピング
open_questions: []
blockers: []
```

**注意**: project-context.yaml には直接書き込まない（Aggregator の責務）。

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| FR 不在 | web-requirements の実行を促す |
| エンティティ抽出不可 | ユーザーに主要データを質問 |
| 循環参照検出 | P2 として記録、設計見直しを提案 |
