---
name: architecture-skeleton
description: This skill should be used when the user asks to "define architecture skeleton", "select technology stack", "create ADR", "define system boundaries", "set NFR policies", or "plan high-level architecture". Designs high-level system architecture, technology selection, and NFR policies for Wave A parallel execution.
version: 1.0.0
model: opus
---

# Architecture Skeleton Skill

Wave A で実行される高レベルアーキテクチャ設計スキル。
技術選定、システム境界、NFR方針を決定し、ADR として記録する。

**実行タイミング**: Wave A（database, design-inventory と並列）

## 前提条件

| 条件 | 必須 | 説明 |
|------|------|------|
| docs/requirements/user-stories.md | ○ | 機能要件（web-requirements 出力） |
| docs/requirements/context_unified.md | ○ | プロジェクトコンテキスト |

## 出力ファイル

| ファイル | 説明 |
|---------|------|
| docs/03_architecture/architecture.md | システム構成（高レベル） |
| docs/03_architecture/adr.md | 技術選定記録 |

## 依存関係

| 種別 | 対象 |
|------|------|
| 前提スキル | web-requirements |
| 並列スキル | database, design-inventory（Wave A） |
| 後続スキル | architecture-detail, api（Wave B） |

## Wave A 契約出力

Blackboard に以下を登録する:

```yaml
contract_outputs:
  - key: decisions.architecture.tech_stack
    value: ["Next.js", "PostgreSQL", "Prisma", ...]
  - key: decisions.architecture.boundaries
    value:
      - name: frontend
        type: SPA
        technology: Next.js
      - name: backend
        type: BFF
        technology: Node.js
      - name: database
        type: RDBMS
        technology: PostgreSQL
  - key: decisions.architecture.nfr_policies
    value:
      authentication:
        method: JWT
        algorithm: RS256
        access_token_ttl: 15m
        refresh_token_ttl: 7d
      error_format: RFC7807
      logging: structured_json
      monitoring: OpenTelemetry
```

## ワークフロー

```
1. 要件（user-stories.md）を読み込み
2. NFR ポリシーを抽出・決定
3. アーキテクチャパターンを選定
4. 技術スタックを決定
5. システム境界を定義
6. ADR を作成
7. architecture.md（高レベル）を生成
8. SendMessage で contract_outputs を Lead に送信
```

## アーキテクチャパターン選定

| プロジェクトタイプ | 推奨パターン | ADR で記録 |
|------------------|-------------|-----------|
| webapp | SPA + BFF | ADR-0001 |
| mobile | Client-Server | ADR-0001 |
| api | Modular Monolith | ADR-0001 |
| batch | Event-Driven | ADR-0001 |
| fullstack | SPA + BFF + API | ADR-0001 |

## NFR ポリシー決定項目

| 項目 | 決定内容 | 後続フェーズへの影響 |
|------|---------|-------------------|
| 認証方式 | JWT / Session / OAuth2 | api, design |
| 認可モデル | RBAC / ABAC / 単純ロール | api, database |
| エラー形式 | RFC7807 / カスタム | api, design |
| ログ形式 | 構造化JSON / プレーン | implementation |
| 監視戦略 | OpenTelemetry / カスタム | infrastructure |

## ADR テンプレート

```markdown
### ADR-0001: アーキテクチャパターン選定

#### コンテキスト
[プロジェクト特性、要件からの制約]

#### 決定
[選定したパターン]

#### 理由
[選定理由、NFR との整合性]

#### 代替案
| 代替案 | 却下理由 |
|--------|----------|
| マイクロサービス | 初期フェーズでは過剰 |

#### 影響
[後続フェーズへの影響、制約]
```

## SendMessage 完了報告

タスク完了時に以下の YAML 形式で Lead に SendMessage を送信する:

```yaml
status: ok | needs_input
severity: null
artifacts:
  - docs/03_architecture/architecture.md
  - docs/03_architecture/adr.md
contract_outputs:
  - key: decisions.architecture.tech_stack
    value: [選定した技術スタック]
  - key: decisions.architecture.boundaries
    value: [定義したシステム境界]
  - key: decisions.architecture.nfr_policies
    value: {NFR ポリシー}
open_questions:
  - "キャッシュ戦略は Wave B（architecture-detail）で決定"
  - "具体的なインフラ構成は Wave B で決定"
blockers: []
```

**注意**: project-context.yaml には直接書き込まない（Aggregator の責務）。

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| 要件不足 | P0 報告、web-requirements へ差し戻し |
| 矛盾する NFR | トレードオフを ADR に記録、P2 報告 |
| 技術選定で迷い | ADR に代替案を記録、needs_input 状態 |
