---
name: context-compressor
description: This skill should be used when the user asks to "compress context", "reduce token count", "summarize design docs", "optimize context window", or "extract signatures". Compresses large context for efficient downstream processing (200k→70k tokens target).
version: 1.0.0
model: haiku
---

# Context Compressor Skill

大規模コンテキストを効率的に圧縮するスキル。
200k→70k トークン（約 65% 削減）を目標とする。

## 使用タイミング

| タイミング | 入力 | 圧縮戦略 |
|-----------|------|---------|
| Wave Aggregator 内 | 統合された Blackboard | Entity Signature Only |
| Phase 8 (Review) | 全設計書 | Decision Summary |
| 既存コード分析 | ソースコード | Semantic Pruning |

## 圧縮戦略

### 1. Semantic Pruning（シグネチャ抽出）

コードから実装詳細を除去し、シグネチャのみを抽出する。

**入力例（100 トークン）:**
```typescript
/**
 * ユーザー情報を取得する
 * @param userId ユーザーID
 * @returns ユーザー情報
 */
async function getUser(userId: string): Promise<User> {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    include: {
      profile: true,
      settings: true,
      roles: {
        include: {
          permissions: true
        }
      }
    }
  });

  if (!user) {
    throw new NotFoundError('User not found');
  }

  return mapToUser(user);
}
```

**出力（30 トークン、70% 削減）:**
```typescript
/** ユーザー情報を取得する */
async function getUser(userId: string): Promise<User>
// 実装: prisma.user.findUnique → User 変換
// 例外: NotFoundError
```

### 2. Entity Signature Only（エンティティ簡略化）

Blackboard のエンティティ情報を属性リストに圧縮する。

**入力例（200 トークン）:**
```yaml
entities:
  - id: ENT-User
    name: User
    attributes:
      - name: id
        type: UUID
        constraints: [PRIMARY KEY]
        description: "ユーザー識別子"
      - name: email
        type: VARCHAR(255)
        constraints: [UNIQUE, NOT NULL]
        description: "メールアドレス"
        validation: "RFC 5322 準拠"
      - name: name
        type: VARCHAR(100)
        constraints: [NOT NULL]
        description: "表示名"
      - name: role
        type: ENUM('admin', 'member', 'guest')
        constraints: [NOT NULL, DEFAULT 'member']
        description: "ユーザーロール"
      - name: created_at
        type: TIMESTAMP
        constraints: [NOT NULL, DEFAULT NOW()]
      - name: updated_at
        type: TIMESTAMP
        constraints: [NOT NULL]
```

**出力（40 トークン、80% 削減）:**
```yaml
entities:
  - id: ENT-User
    name: User
    attributes: [id(UUID,PK), email(VARCHAR,UNIQUE), name(VARCHAR), role(ENUM), created_at(TS), updated_at(TS)]
    # 詳細: 04_data_structure/data_structure.md
```

### 3. Chain of Density（段階的要約）

ドキュメントをエンティティ保持しながら段階的に要約する。

**ステップ:**
1. 初回要約: 全体の 50% に圧縮（重要エンティティを保持）
2. 2回目: さらに 50% に圧縮（主要決定事項のみ）
3. 最終: 必要に応じてさらに圧縮

**要約ルール:**
- ID（FR-XXX, SC-XXX, API-XXX 等）は必ず保持
- 決定事項（ADR）のタイトルと結論は保持
- 具体例・詳細説明は削除
- 参照リンクを追加（「詳細は XX を参照」）

### 4. Decision Summary（決定事項のみ）

ADR と Blackboard から決定事項のみを抽出する。

**出力形式:**
```markdown
## 決定事項サマリー

### アーキテクチャ
- ADR-0001: SPA + BFF 採用
- ADR-0002: PostgreSQL + Prisma 採用
- 認証: JWT (RS256)、Access 15分、Refresh 7日

### エンティティ
- ENT-User: id, email, name, role
- ENT-Post: id, title, content, author_id, status

### API
- API-001: GET /users → User[]
- API-002: POST /users → User
- API-003: GET /users/:id → User

### 画面
- SC-001: ログイン（Auth）
- SC-002: ダッシュボード（Member）
- SC-003: ユーザー一覧（Admin）
```

## 圧縮レベル

| レベル | 圧縮率 | 用途 |
|--------|--------|------|
| Light | 30% | 軽微な削減、詳細維持 |
| Medium | 50% | Wave 間引き継ぎ |
| Heavy | 70% | Review 時の全体把握 |
| Extreme | 80%+ | トークン制限が厳しい場合 |

## ワークフロー

```
1. 入力コンテキストを分析
2. コンテンツ種別を判定（コード/YAML/Markdown）
3. 適切な圧縮戦略を選択
4. 圧縮を実行
5. ID・決定事項の保持を検証
6. 参照リンクを追加
7. 圧縮後コンテキストを出力
```

## 圧縮品質チェック

| チェック項目 | 失敗時の対応 |
|-------------|------------|
| 全 ID が保持されている | 圧縮をやり直し |
| 決定事項が失われていない | 該当部分を復元 |
| 参照リンクが有効 | リンク先を確認 |
| トークン数が目標以下 | さらに圧縮 or 分割 |

## 入出力例

### Wave Aggregator での使用

**入力（Blackboard 全体: 50k トークン）:**
```yaml
blackboard:
  decisions:
    architecture: {...}  # 10k
    entities: [...]      # 15k
    api_resources: [...]  # 15k
    screens: [...]        # 10k
```

**出力（圧縮後: 15k トークン）:**
```yaml
blackboard_summary:
  architecture:
    tech_stack: [Next.js, PostgreSQL, Prisma]
    auth: JWT/RS256
    # 詳細: 03_architecture/architecture.md
  entities: [ENT-User(6attr), ENT-Post(8attr), ...]
    # 詳細: 04_data_structure/data_structure.md
  api_resources: [API-001..API-020]
    # 詳細: 05_api_design/api_design.md
  screens: [SC-001..SC-030]
    # 詳細: 06_screen_design/screen_list.md
```

## SendMessage 完了報告

圧縮完了時に以下の YAML 形式で呼び出し元（通常は Aggregator）に結果を返す:

```yaml
status: ok
severity: null
artifacts: []
contract_outputs:
  - key: compressed_context
    value: {...}
  - key: compression_stats
    value:
      original_tokens: 50000
      compressed_tokens: 15000
      compression_ratio: 0.70
      preserved_ids: [FR-001, SC-001, ...]
open_questions: []
blockers: []
```

**注意**: project-context.yaml には直接書き込まない（Aggregator の責務）。

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| ID 消失 | 圧縮レベルを下げてやり直し |
| 目標未達 | さらに圧縮 or コンテキスト分割を提案 |
| 構造破壊 | 圧縮戦略を変更 |
