# Phase: Architecture Skeleton

高レベルアーキテクチャ設計フェーズ。
技術選定、システム境界、NFR 方針を決定し、ADR として記録する。

## Contract (YAML)

```yaml
phase_id: "3a"
required_artifacts:
  - docs/requirements/user-stories.md
  - docs/requirements/context_unified.md
  - project.constraints.approved_tech_stack   # Blackboard or ユーザー入力

outputs:
  - path: docs/03_architecture/architecture.md
    required: true
  - path: docs/03_architecture/adr.md
    required: true

contract_outputs:
  - key: decisions.architecture.tech_stack
    type: array
    description: "選定した技術スタックのリスト"
  - key: decisions.architecture.user_constraints
    type: object
    description: "ユーザー承認済み技術スタック（audit trail）"
  - key: decisions.architecture.boundaries
    type: array
    description: "システム境界定義（name, type, technology）"
  - key: decisions.architecture.nfr_policies
    type: object
    description: "NFR ポリシー（認証方式、エラー形式、ログ形式等）"
  - key: decisions.nfr_measurability
    type: object
    description: "NFR-ID ごとの target/measurement/pass_criteria"

quality_gates:
  - "全 FR-ID が最低1つのシステム境界またはレイヤーにマッピングされていること"
  - "NFR は target/measurement/pass_criteria の3項目が定義されていること"
  - "mode: specified の場合、ユーザー指定技術が全て設計に反映されていること"
```

## 入力要件

| 入力 | 必須 | 説明 |
|------|------|------|
| docs/requirements/user-stories.md | ○ | 機能要件（Gherkin 形式） |
| docs/requirements/context_unified.md | ○ | プロジェクトコンテキスト |
| approved_tech_stack | ○ | ユーザー承認済み技術スタック（`mode: auto` の場合は自律選定） |

## 出力ファイル

| ファイル | 説明 |
|---------|------|
| docs/03_architecture/architecture.md | システム構成（高レベル） |
| docs/03_architecture/adr.md | 技術選定記録（Architecture Decision Records） |

### architecture.md 必須セクション

1. 技術スタック選定理由
2. アーキテクチャパターン
3. レイヤー構成
4. システム境界定義
5. NFR 測定可能性定義

### adr.md 必須セクション

各 ADR に以下を含む:
1. コンテキスト
2. 決定
3. 理由
4. 代替案（テーブル形式）
5. 影響

## ワークフロー

```
1. 要件（user-stories.md）を読み込み
2. NFR ポリシーを抽出・決定
3. アーキテクチャパターンを選定
4. 技術スタックを検証・詳細化
   4a. approved_tech_stack を確認
   4b. mode: auto → 自律選定
   4c. mode: specified → ユーザー指定を必須制約として採用
   4d. 未指定カテゴリ（空文字列）は自律選定で補完
   4e. 互換性検証（問題があれば報告）
5. システム境界を定義
6. ADR を作成（ユーザー指定技術がある場合「ユーザー制約による選定」として記録）
7. architecture.md を生成
8. contract_outputs を出力
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
例: Next.js 指定 → SPA + BFF パターン。Django 指定 → MVC モノリスを検討。

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
### ADR-XXXX: [タイトル]

#### コンテキスト
[プロジェクト特性、要件からの制約]

#### 決定
[選定したパターン/技術]

#### 理由
[選定理由、NFR との整合性]

#### 代替案
| 代替案 | 却下理由 |
|--------|----------|
| [代替1] | [理由] |

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

**データフロー**: architecture-skeleton → Blackboard `nfr_measurability` → impl-test `nonfunctional_test_plan.md` → review 検証

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| 要件不足 | P0 報告、web-requirements へ差し戻し |
| 矛盾する NFR | トレードオフを ADR に記録、P2 報告 |
| 技術選定で迷い（mode: auto 時） | ADR に代替案を記録、入力要請 |
| ユーザー指定技術の互換性問題 | ADR に記録、入力要請。ユーザー指定は変更不可 |
| ユーザー指定技術間の競合 | 補完側を調整して互換性を確保。調整不可の場合は入力要請 |
