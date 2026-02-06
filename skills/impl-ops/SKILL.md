---
name: impl-ops
description: This skill should be used when the user asks to "design observability", "create SLI/SLO", "write incident response plan", "design monitoring", "create backup strategy", "plan migration", or "write operations runbook". Creates operations and infrastructure design documents.
version: 1.0.0
---

# Operations Design Skill

運用設計ドキュメントを作成するスキル。
可観測性設計、インシデント対応、バックアップ/DR、移行計画を策定する。

## 前提条件

| 条件 | 必須 | 説明 |
|------|------|------|
| docs/03_architecture/architecture.md | ○ | 技術スタック・アーキテクチャ |
| docs/03_architecture/infrastructure.md | ○ | インフラ設計 |
| docs/03_architecture/security.md | ○ | セキュリティ設計 |
| docs/project-context.yaml | ○ | Blackboard（NFR、project.profile） |

## 出力ファイル

| ファイル | テンプレート | 説明 | 生成条件 |
|---------|-------------|------|---------|
| docs/07_implementation/operations.md | {baseDir}/references/operations.md | 運用手順書 | 常時 |
| docs/07_implementation/observability_design.md | {baseDir}/references/observability_design.md | 可観測性設計 | 常時 |
| docs/07_implementation/incident_response.md | {baseDir}/references/incident_response.md | インシデント対応計画 | 常時 |
| docs/07_implementation/backup_restore_dr.md | {baseDir}/references/backup_restore_dr.md | バックアップ/DR | profile.sla_tier ≠ basic |
| docs/07_implementation/migration_plan.md | {baseDir}/references/migration_plan.md | 移行計画 | profile.has_migration = true |

## 依存関係

| 種別 | 対象 |
|------|------|
| 前提スキル | architecture, architecture-detail |
| 後続スキル | review |

## 条件付き生成

project-context.yaml の `project.profile` に基づき出力を制御:

| 条件 | 生成する/しない |
|------|--------------|
| profile.sla_tier = basic | backup_restore_dr.md をスキップ |
| profile.has_migration = false | migration_plan.md をスキップ |

profile が未設定の場合はデフォルト（全ファイル生成）とする。

## ワークフロー

```
1. アーキテクチャ・インフラ設計を読み込み
2. project.profile から条件付き生成の判定
3. 運用手順書を生成（日次/週次/月次タスク、デプロイ手順）
4. 可観測性設計を策定（SLI/SLO、メトリクス、ログ、アラート）
5. インシデント対応計画を策定（分類、体制、エスカレーション）
6. バックアップ/DR計画を策定（条件付き）
7. 移行計画を策定（条件付き）
```

## SendMessage 完了報告

タスク完了時に以下の YAML 形式で Lead に SendMessage を送信する:

```yaml
status: ok
severity: null
artifacts:
  - docs/07_implementation/operations.md
  - docs/07_implementation/observability_design.md
  - docs/07_implementation/incident_response.md
  # 以下は条件付き
  - docs/07_implementation/backup_restore_dr.md
  - docs/07_implementation/migration_plan.md
contract_outputs: []
open_questions: []
blockers: []
```

**注意**: project-context.yaml には直接書き込まない（Aggregator の責務）。

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| infrastructure.md 不在 | WARNING: 汎用的な運用設計で代替 |
| project.profile 未設定 | 全ファイルをデフォルト生成（条件付きスキップなし） |
