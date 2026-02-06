---
name: architecture-skeleton
description: This skill should be used when the user asks to "define architecture skeleton", "select technology stack", "create ADR", "define system boundaries", "set NFR policies", or "plan high-level architecture". Designs high-level system architecture, technology selection, and NFR policies for Wave A parallel execution.
version: 1.1.0
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
| ユーザー承認済み技術スタック | ○ | スポーンプロンプト経由で受領（`mode: auto` の場合は自律選定） |

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
4. 技術スタックを検証・詳細化
   4a. USER_APPROVED_TECH_STACK を確認
   4b. mode: auto → 従来通り自律選定
   4c. mode: specified → ユーザー指定を必須制約として採用
   4d. 未指定カテゴリ（空文字列）は自律選定で補完
   4e. 互換性検証（問題あれば needs_input で Lead に報告）
5. システム境界を定義
6. ADR を作成（ユーザー指定技術がある場合「ユーザー制約による選定」として記録）
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

**注意**: ユーザーが技術スタックを指定した場合（mode: specified）、そのスタックと最も相性の良いパターンを優先する。
例: ユーザーが Next.js を指定 → SPA + BFF パターンを優先。Django を指定 → MVC モノリスを検討。

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

## NFR 測定可能性定義

各 NFR に対して、以下の3要素を定義する（IPA 非機能要求グレード準拠）:

| 要素 | 説明 | 例 |
|------|------|-----|
| target | 達成目標（定量値） | API応答時間 p95 < 200ms |
| measurement | 測定方法・ツール | k6 負荷テスト (100同時ユーザー) |
| pass_criteria | 合否基準 | p95 < 200ms かつ p99 < 500ms |

### 定義テンプレート

| NFR-ID | カテゴリ | target | measurement | pass_criteria |
|--------|---------|--------|-------------|---------------|
| NFR-PERF-001 | パフォーマンス | API応答時間 p95 < 200ms | k6 負荷テスト (100同時ユーザー) | p95 < 200ms かつ p99 < 500ms |
| NFR-SEC-001 | セキュリティ | OWASP Top 10 脆弱性ゼロ | OWASP ZAP フルスキャン | High/Critical = 0 |
| NFR-AVL-001 | 可用性 | 稼働率 99.9% | 外形監視（1分間隔） | 月間ダウンタイム < 43分 |

**データフロー**: Phase 3a → Aggregator → Blackboard `nfr_measurability` → Phase 7 `nonfunctional_test_plan.md` → Phase 8 検証

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
  - key: decisions.architecture.user_constraints
    value: {ユーザー承認済み技術スタック（mode, 各カテゴリ）をそのまま転記}
  - key: decisions.architecture.boundaries
    value: [定義したシステム境界]
  - key: decisions.architecture.nfr_policies
    value: {NFR ポリシー}
  - key: decisions.nfr_measurability
    value:
      NFR-PERF-001:
        target: "API応答時間 p95 < 200ms"
        measurement: "k6 負荷テスト"
        pass_criteria: "p95 < 200ms かつ p99 < 500ms"
      # 全 NFR-ID について定義
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
| 技術選定で迷い（mode: auto 時） | ADR に代替案を記録、needs_input 状態 |
| ユーザー指定技術の互換性問題 | ADR に代替案を記録、needs_input で Lead に報告。ユーザー指定は変更不可 |
| ユーザー指定技術間の競合 | 補完側を調整して互換性を確保。調整不可の場合 needs_input で Lead に報告 |
