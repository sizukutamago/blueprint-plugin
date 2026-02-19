# Phase: Operations Design

運用設計ドキュメントを作成するフェーズ。
可観測性設計、インシデント対応、バックアップ/DR、移行計画を策定する。

## Contract (YAML)

```yaml
phase_id: "7c"
required_artifacts:
  - docs/03_architecture/architecture.md
  - docs/03_architecture/infrastructure.md
  - docs/03_architecture/security.md
  - docs/project-context.yaml                      # Blackboard（NFR、project.profile）

outputs:
  - path: docs/07_implementation/operations.md
    required: true
  - path: docs/07_implementation/observability_design.md
    required: true
  - path: docs/07_implementation/incident_response.md
    required: true
  - path: docs/07_implementation/backup_restore_dr.md
    required: false
    condition: "profile.sla_tier != basic"
  - path: docs/07_implementation/migration_plan.md
    required: false
    condition: "profile.has_migration == true"

contract_outputs: []

quality_gates:
  - "SLI/SLO が architecture.md の NFR ポリシーと整合していること"
  - "インシデント対応のエスカレーションパスが定義されていること"
  - "条件付きファイルの生成/スキップが profile 設定と一致していること"
```

## 入力要件

| 入力 | 必須 | 説明 |
|------|------|------|
| docs/03_architecture/architecture.md | ○ | 技術スタック・アーキテクチャ |
| docs/03_architecture/infrastructure.md | ○ | インフラ設計 |
| docs/03_architecture/security.md | ○ | セキュリティ設計 |
| docs/project-context.yaml | ○ | Blackboard（NFR、project.profile） |

## 出力ファイル

| ファイル | テンプレート | 説明 | 生成条件 |
|---------|-------------|------|---------|
| docs/07_implementation/operations.md | references/operations.md | 運用手順書 | 常時 |
| docs/07_implementation/observability_design.md | references/observability_design.md | 可観測性設計 | 常時 |
| docs/07_implementation/incident_response.md | references/incident_response.md | インシデント対応計画 | 常時 |
| docs/07_implementation/backup_restore_dr.md | references/backup_restore_dr.md | バックアップ/DR | profile.sla_tier != basic |
| docs/07_implementation/migration_plan.md | references/migration_plan.md | 移行計画 | profile.has_migration == true |

## 条件付き生成

Blackboard の `project.profile` に基づき出力を制御する:

| 条件 | 生成する/しない |
|------|--------------|
| profile.sla_tier = basic | backup_restore_dr.md をスキップ |
| profile.has_migration = false | migration_plan.md をスキップ |

**profile 未設定時のデフォルト動作**: `sla_tier: basic`, `has_migration: false` として扱う（backup_restore_dr.md, migration_plan.md はスキップ）。profile の未設定自体を P2 として記録する。

## ワークフロー

```
1. アーキテクチャ・インフラ設計を読み込み
2. Blackboard から project.profile を取得し条件付き生成の判定
3. 運用手順書を生成
   - 日次/週次/月次運用タスク
   - デプロイ手順（ロールバック含む）
   - メンテナンスウィンドウ
4. 可観測性設計を策定
   - SLI/SLO 定義
   - メトリクス収集（CPU/メモリ/レイテンシ/エラー率）
   - ログ設計（構造化ログ、集約、保持期間）
   - アラート設計（閾値、通知先、エスカレーション）
5. インシデント対応計画を策定
   - インシデント分類（Severity 1-4）
   - 対応体制
   - エスカレーションパス
   - ポストモーテムプロセス
6. バックアップ/DR 計画を策定（条件付き: sla_tier != basic）
   - バックアップ戦略（頻度、保持期間、暗号化）
   - RTO/RPO 定義
   - DR 手順
7. 移行計画を策定（条件付き: has_migration == true）
   - 移行戦略（Big Bang / Blue-Green / Canary）
   - データ移行手順
   - ロールバック計画
   - Go/No-Go 基準
8. contract_outputs を出力
```

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| infrastructure.md 不在 | WARNING: 汎用的な運用設計で代替 |
| project.profile 未設定 | sla_tier: basic, has_migration: false として扱い条件付きファイルはスキップ。P2 として記録 |
