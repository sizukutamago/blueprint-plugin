---
name: wave-aggregator
description: This skill should be used when the user asks to "aggregate wave results", "merge parallel outputs", "unify design decisions", "resolve conflicts between phases", or "update blackboard". Aggregates outputs from parallel Wave A/B executions and updates the Blackboard as the sole writer teammate.
version: 3.0.0
---

# Wave Aggregator Skill

Wave A/B 完了後に各 teammate の出力を統合し、Blackboard を更新するスキル。
**project-context.yaml の唯一の書き込み者**（単一ライター原則）。
Two-step Reduce（JSON正規化 + Adjudication Pass）で矛盾を解消する。

agent-teams モードでは**常駐 teammate** として Wave A〜B を通じて生存し、
Lead から SendMessage で統合依頼を受ける。

## 前提条件

| 条件 | 必須 | 説明 |
|------|------|------|
| Wave A/B の出力ファイル | ○ | 統合対象 |
| docs/project-context.yaml | ○ | Blackboard 更新先 |
| Lead からの contract_outputs | ○ | 各 teammate の SendMessage 出力（Lead が転送） |

## 出力ファイル

| ファイル | 説明 |
|---------|------|
| docs/project-context.yaml | Blackboard 更新 |
| docs/wave_X/unified_context.md | 統合コンテキスト（オプション） |
| docs/wave_X/conflicts.md | 矛盾レポート（矛盾がある場合） |

## 依存関係

| 種別 | 対象 |
|------|------|
| 前提スキル | Wave A: architecture-skeleton, database, design-inventory |
| 前提スキル | Wave B: api, architecture-detail |
| 後続スキル | Wave B（Wave A 後）/ design-detail, implementation（Wave B 後） |

## ワークフロー

```
1. Lead から SendMessage で統合依頼 + contract_outputs を受信
2. Step 1: JSON正規化（contract_outputs を Blackboard スキーマに変換）
3. Step 2: Adjudication Pass（矛盾検出・解消）
4. Blackboard（project-context.yaml）を更新
5. 矛盾があれば Lead に P1 報告
6. SendMessage で統合完了を Lead に報告
```

## Two-step Reduce

### Step 1: JSON正規化

各エージェントの `contract_outputs` を収集し、Blackboard スキーマに正規化する。

```yaml
# 入力例: architecture-skeleton の出力
contract_outputs:
  - key: decisions.architecture.tech_stack
    value: ["Next.js", "PostgreSQL", "Prisma"]
  - key: decisions.architecture.boundaries
    value: ["frontend", "backend", "database"]

# 入力例: database の出力
contract_outputs:
  - key: decisions.entities
    value:
      - id: ENT-User
        name: User
        attributes: [id, email, name, role]

# 正規化後: Blackboard 形式
blackboard:
  decisions:
    architecture:
      tech_stack: ["Next.js", "PostgreSQL", "Prisma"]
      boundaries: ["frontend", "backend", "database"]
    entities:
      - id: ENT-User
        name: User
        attributes: [id, email, name, role]
```

### Step 2: Adjudication Pass

矛盾を検出し、解消ルールを適用する。

| 矛盾パターン | 検出方法 | 解消ルール |
|-------------|----------|-----------|
| 同一キーに異なる値 | キー比較 | 上流フェーズを優先 |
| 参照先不在 | ID 存在チェック | P1 として報告、差し戻し |
| 重複 ID | ID ユニーク検証 | 先勝ち or 連番付与 |
| 循環参照 | 依存グラフ検証 | P1 として報告 |

**矛盾検出例:**
```yaml
conflicts:
  - type: missing_reference
    severity: P1
    source: api
    target: database
    message: "API-003 が参照する ENT-Order が未定義"
    resolution: "database フェーズへ差し戻し"
```

## Blackboard 更新

### 更新対象フィールド

| フィールド | Wave A | Wave B |
|-----------|--------|--------|
| `blackboard.decisions.architecture` | ○ | ○（detail 追加） |
| `blackboard.decisions.entities` | ○ | - |
| `blackboard.decisions.api_resources` | - | ○ |
| `blackboard.decisions.screens` | ○（inventory） | ○（detail 追加） |
| `traceability.*` | マージ | マージ |

**注意**: v3.0 で `pending_questions`、`conflicts`、`wave_status`、`contracts` は削除済み。
未解決疑問は `open_questions` として SendMessage で Lead に報告し、Lead が TaskCreate で管理する。

### 更新手順

```yaml
# 1. blackboard.decisions をマージ
blackboard:
  decisions:
    # 各 teammate の contract_outputs をキー別にマージ
    architecture:
      tech_stack: [...]    # arch-skeleton から
    entities:
      - id: ENT-User       # database から
    screens:
      - id: SC-001         # design-inventory から

# 2. traceability をマージ
traceability:
  fr_to_ent:
    FR-001: [ENT-User]     # database から
  fr_to_sc:
    FR-001: [SC-001]       # design-inventory から
```

## コンテキスト圧縮（オプション）

Blackboard が大きくなった場合、後続フェーズへの入力を圧縮する。

### 圧縮戦略

| 戦略 | 適用条件 | 圧縮率目標 |
|------|----------|-----------|
| Semantic Pruning | 実装詳細が不要な場合 | 50% |
| Entity Signature Only | API 設計時 | 30% |
| Decision Summary | 後半フェーズ | 20% |

```yaml
# 圧縮前
blackboard:
  decisions:
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
          # ... 20+ attributes

# 圧縮後（Entity Signature Only）
blackboard:
  decisions:
    entities:
      - id: ENT-User
        name: User
        attributes: [id, email, name, role, created_at, updated_at]
        # 詳細は 04_data_structure/data_structure.md を参照
```

## SendMessage 統合完了報告

Wave 統合完了時に以下の YAML 形式で Lead に SendMessage を送信する:

```yaml
status: ok | conflict
updated_keys:
  - decisions.architecture.tech_stack
  - decisions.entities
  - traceability.fr_to_ent
conflicts:
  - type: missing_reference
    severity: P1
    source: api
    target: database
    message: "API-003 が参照する ENT-Order が未定義"
    resolution: "database フェーズへ差し戻し"
compression:
  strategy: entity_signature_only
  original_tokens: 50000
  compressed_tokens: 15000
open_questions:
  # 各 teammate の未解決疑問を集約
```

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| contract_outputs 不在 | 該当エージェントの再実行を要請 |
| スキーマ不整合 | 正規化を試み、失敗したら P1 報告 |
| 矛盾解消不能 | P1 として差し戻し先を特定 |
| Blackboard 更新失敗 | ロールバック、再試行（最大3回） |

## モデル割り当て

| 処理 | モデル | 理由 |
|------|--------|------|
| 矛盾検出 | opus | 複雑な整合性判断 |
| JSON正規化 | haiku | 単純な変換処理 |
| コンテキスト圧縮 | haiku | ルーティン作業 |
