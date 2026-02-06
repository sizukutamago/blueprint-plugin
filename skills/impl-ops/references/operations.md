---
doc_type: "operations"
version: "{{VERSION}}"
status: "{{STATUS}}"
updated_at: "{{UPDATED_AT}}"
owners:
  - "{{OWNER_EMAIL}}"
tags:
  - "実装"
  - "運用"
  - "Runbook"
---

# 運用手順書（Runbook）

---

## 目次

1. [概要](#概要)
2. [日常運用](#日常運用)
3. [デプロイ手順](#デプロイ手順)
4. [メンテナンス手順](#メンテナンス手順)
5. [関連ドキュメント](#関連ドキュメント)
6. [変更履歴](#変更履歴)

---

## 概要

### 本ドキュメントの目的

本ドキュメントは、システムの日常運用・デプロイ・メンテナンスに必要な手順を定義する。
障害対応は `incident_response.md`、バックアップ/DRは `backup_restore_dr.md` を参照のこと。

### 対象読者

| 読者 | 用途 |
|------|------|
| {{READER_ROLE}} | {{READER_PURPOSE}} |

### 連絡先一覧

| 役割 | 担当者 | 連絡先 |
|------|--------|--------|
| {{ROLE}} | {{PERSON}} | {{CONTACT}} |

---

## 日常運用

### 日次タスク

| タスク | 実施時間 | 担当 | 確認方法 |
|--------|----------|------|----------|
| {{TASK}} | {{TIME}} | {{ASSIGNEE}} | {{VERIFICATION}} |

### 週次タスク

| タスク | 実施曜日 | 担当 | 確認方法 |
|--------|----------|------|----------|
| {{TASK}} | {{DAY_OF_WEEK}} | {{ASSIGNEE}} | {{VERIFICATION}} |

### 月次タスク

| タスク | 実施日 | 担当 | 確認方法 |
|--------|--------|------|----------|
| {{TASK}} | {{DAY_OF_MONTH}} | {{ASSIGNEE}} | {{VERIFICATION}} |

### ヘルスチェック手順

#### エンドポイント一覧

| サービス | エンドポイント | 期待レスポンス | チェック間隔 |
|---------|--------------|--------------|------------|
| {{SERVICE}} | {{ENDPOINT}} | {{EXPECTED_RESPONSE}} | {{INTERVAL}} |

#### 手動ヘルスチェック

```bash
{{HEALTH_CHECK_COMMAND}}
```

---

## デプロイ手順

### 通常デプロイ

#### 事前チェック

- [ ] CI/CD パイプラインが全て成功
- [ ] ステージング環境での動作確認完了
- [ ] {{PRE_DEPLOY_CHECK}}

#### デプロイ手順

```bash
{{DEPLOY_COMMANDS}}
```

#### 事後確認

- [ ] ヘルスチェック正常
- [ ] 主要機能の動作確認
- [ ] {{POST_DEPLOY_CHECK}}

### ホットフィックスデプロイ

#### 発動条件

{{HOTFIX_TRIGGER_CONDITION}}

#### ホットフィックス手順

```bash
{{HOTFIX_COMMANDS}}
```

### ロールバック手順

#### ロールバック判定基準

| 条件 | 基準 |
|------|------|
| {{ROLLBACK_CONDITION}} | {{ROLLBACK_CRITERIA}} |

#### ロールバック手順

```bash
{{ROLLBACK_COMMANDS}}
```

#### ロールバック後の確認

- [ ] サービス正常稼働
- [ ] データ整合性確認
- [ ] {{POST_ROLLBACK_CHECK}}

---

## メンテナンス手順

### 計画メンテナンス

#### 事前告知

| 通知タイミング | 通知先 | 通知方法 |
|--------------|--------|---------|
| {{TIMING}} | {{TARGET}} | {{METHOD}} |

#### メンテナンスモード切替

```bash
# メンテナンスモード開始
{{MAINTENANCE_ON_COMMAND}}

# メンテナンスモード終了
{{MAINTENANCE_OFF_COMMAND}}
```

#### 事後確認

- [ ] 全サービスの正常稼働
- [ ] メンテナンスモード解除の確認
- [ ] {{POST_MAINTENANCE_CHECK}}

### データベースマイグレーション

#### 事前準備

- [ ] マイグレーションスクリプトのレビュー完了
- [ ] バックアップ取得済み
- [ ] ロールバックスクリプト準備済み

#### マイグレーション手順

```bash
{{MIGRATION_COMMANDS}}
```

#### ロールバック手順

```bash
{{MIGRATION_ROLLBACK_COMMANDS}}
```

### 証明書更新

| 証明書 | 有効期限 | 更新方法 | 担当 |
|--------|---------|---------|------|
| {{CERT_NAME}} | {{EXPIRY}} | {{RENEWAL_METHOD}} | {{ASSIGNEE}} |

#### 更新手順

```bash
{{CERT_RENEWAL_COMMANDS}}
```

---

## 関連ドキュメント

| ドキュメント | リンク |
|-------------|--------|
| インフラストラクチャ設計書 | [infrastructure.md](../03_architecture/infrastructure.md) |
| セキュリティ設計書 | [security.md](../03_architecture/security.md) |
| 環境・デプロイ設定 | [environment.md](./environment.md) |
| 可観測性設計書 | [observability_design.md](./observability_design.md) |
| インシデント対応計画 | [incident_response.md](./incident_response.md) |
| バックアップ/DR計画 | [backup_restore_dr.md](./backup_restore_dr.md) |

---

## 変更履歴

| 日付 | バージョン | 変更者 | 変更内容 |
|------|-----------|--------|----------|
| {{DATE}} | 1.0.0 | {{AUTHOR}} | 初版作成 |
