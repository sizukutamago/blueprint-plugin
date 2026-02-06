---
doc_type: "backup_restore_dr"
version: "{{VERSION}}"
status: "{{STATUS}}"
updated_at: "{{UPDATED_AT}}"
owners:
  - "{{OWNER_EMAIL}}"
tags:
  - "実装"
  - "バックアップ"
  - "DR"
  - "災害対策"
coverage:
  nfr: []
---

# バックアップ/リストア/DR計画

---

## 目次

1. [バックアップ/DR方針](#バックアップdr方針)
2. [RTO/RPO定義](#rtorpo定義)
3. [バックアップ手順](#バックアップ手順)
4. [リストア手順](#リストア手順)
5. [DR計画](#dr計画)
6. [DR訓練計画](#dr訓練計画)
7. [コスト見積もり](#コスト見積もり)
8. [関連ドキュメント](#関連ドキュメント)
9. [変更履歴](#変更履歴)

---

## バックアップ/DR方針

### 目的

本ドキュメントは、システムのバックアップ/リストア/災害復旧（DR）に関する計画を定義する。
データ損失の最小化とサービス継続性の確保を目的とする。

### 関連NFR

| ID | 概要 | 要求値 |
|----|------|--------|
| {{NFR_ID}} | {{NFR_SUMMARY}} | {{NFR_VALUE}} |

### 規制要件

| 規制/基準 | 要件 | 対応 |
|-----------|------|------|
| {{REGULATION}} | {{REQUIREMENT}} | {{COMPLIANCE}} |

---

## RTO/RPO定義

### サービス/データ別 RTO/RPO

| サービス/データ | RTO | RPO | バックアップ方式 | 保持期間 |
|---------------|-----|-----|---------------|---------|
| {{SERVICE_OR_DATA}} | {{RTO}} | {{RPO}} | {{BACKUP_METHOD}} | {{RETENTION}} |

### 用語定義

| 用語 | 定義 |
|------|------|
| RTO（Recovery Time Objective） | 障害発生からサービス復旧までの目標時間 |
| RPO（Recovery Point Objective） | 障害発生時に許容されるデータ損失の最大時間幅 |

---

## バックアップ手順

### 自動バックアップ設定

| 対象 | 方式 | スケジュール | 保持世代 | 保存先 |
|------|------|-----------|---------|--------|
| {{TARGET}} | {{METHOD}} | {{SCHEDULE}} | {{GENERATIONS}} | {{DESTINATION}} |

#### バックアップ設定例

```bash
{{BACKUP_CONFIG_COMMAND}}
```

### 手動バックアップ

#### 実行手順

```bash
# 手動バックアップ取得
{{MANUAL_BACKUP_COMMAND}}
```

#### 実行が必要なケース

| ケース | 理由 |
|--------|------|
| 大規模マイグレーション前 | ロールバック用のスナップショット確保 |
| 重要データ変更前 | データ整合性保証 |
| {{CUSTOM_CASE}} | {{CUSTOM_REASON}} |

### バックアップ検証方法

| 検証項目 | 方法 | 頻度 |
|---------|------|------|
| バックアップ完了確認 | {{COMPLETION_CHECK}} | 日次 |
| バックアップ整合性確認 | {{INTEGRITY_CHECK}} | 週次 |
| リストアテスト | {{RESTORE_TEST}} | {{RESTORE_TEST_FREQ}} |

---

## リストア手順

### フルリストア

#### 前提条件

- [ ] リストア先環境の準備完了
- [ ] バックアップデータの整合性確認済み
- [ ] {{FULL_RESTORE_PREREQ}}

#### 手順

```bash
# Step 1: サービス停止
{{SERVICE_STOP_COMMAND}}

# Step 2: バックアップからリストア
{{FULL_RESTORE_COMMAND}}

# Step 3: 整合性確認
{{INTEGRITY_CHECK_COMMAND}}

# Step 4: サービス起動
{{SERVICE_START_COMMAND}}
```

### ポイントインタイムリカバリ（PITR）

#### 前提条件

- [ ] WAL/binlog が有効であること
- [ ] 復旧対象時点のバックアップが存在すること

#### 手順

```bash
# 指定時点へのリカバリ
{{PITR_COMMAND}}
```

### 部分リストア

#### ユースケース

| ケース | 対象 | 手順 |
|--------|------|------|
| テーブル単位のリストア | {{TABLE}} | {{TABLE_RESTORE_STEPS}} |
| レコード単位の復元 | {{RECORD}} | {{RECORD_RESTORE_STEPS}} |
| ファイル単位のリストア | {{FILE}} | {{FILE_RESTORE_STEPS}} |

### リストア検証チェックリスト

- [ ] データ件数の照合（バックアップ時点 vs リストア後）
- [ ] 主要テーブルのサンプルデータ確認
- [ ] 参照整合性の確認
- [ ] アプリケーションからの接続確認
- [ ] 主要機能の動作確認
- [ ] {{CUSTOM_VERIFICATION}}

---

## DR計画

### DRサイト構成

| 項目 | プライマリサイト | DRサイト |
|------|---------------|---------|
| リージョン | {{PRIMARY_REGION}} | {{DR_REGION}} |
| 構成 | {{PRIMARY_CONFIG}} | {{DR_CONFIG}} |
| データ同期 | - | {{SYNC_METHOD}} |
| 同期遅延 | - | {{SYNC_LAG}} |

#### DR構成図

```mermaid
graph TB
    subgraph Primary["プライマリサイト（{{PRIMARY_REGION}}）"]
        PA[Application] --> PD[Database]
        PA --> PS[Storage]
    end
    subgraph DR["DRサイト（{{DR_REGION}}）"]
        DA[Application] --> DD[Database]
        DA --> DS[Storage]
    end
    PD -->|{{SYNC_METHOD}}| DD
    PS -->|{{STORAGE_SYNC}}| DS
```

### フェイルオーバー手順

#### 判定基準

| 条件 | 判定 |
|------|------|
| プライマリサイト完全停止 | フェイルオーバー実施 |
| {{FAILOVER_CONDITION}} | {{FAILOVER_DECISION}} |

#### 手順

```bash
# Step 1: プライマリサイトの状態確認
{{PRIMARY_CHECK_COMMAND}}

# Step 2: DNSフェイルオーバー
{{DNS_FAILOVER_COMMAND}}

# Step 3: DRサイトのスケールアップ
{{DR_SCALEUP_COMMAND}}

# Step 4: 動作確認
{{DR_VERIFICATION_COMMAND}}
```

#### フェイルオーバー時の確認

- [ ] DNS 切り替え完了
- [ ] DRサイトでのサービス正常稼働
- [ ] データ同期の最終時点確認（データ損失の特定）
- [ ] ユーザーへのステータス通知
- [ ] {{CUSTOM_FAILOVER_CHECK}}

### フェイルバック手順

#### 前提条件

- [ ] プライマリサイトの復旧完了
- [ ] データの再同期完了
- [ ] {{FAILBACK_PREREQ}}

#### 手順

```bash
# Step 1: プライマリサイトの正常性確認
{{PRIMARY_RECOVERY_CHECK}}

# Step 2: データ再同期
{{DATA_RESYNC_COMMAND}}

# Step 3: DNS切り戻し
{{DNS_FAILBACK_COMMAND}}

# Step 4: DRサイトのスケールダウン
{{DR_SCALEDOWN_COMMAND}}
```

### RPO/RTOの検証方法

| 指標 | 検証方法 | 目標値 | 計測タイミング |
|------|---------|--------|-------------|
| RTO | フェイルオーバー訓練での実測 | {{RTO_TARGET}} | {{RTO_TIMING}} |
| RPO | 同期遅延のモニタリング | {{RPO_TARGET}} | {{RPO_TIMING}} |

---

## DR訓練計画

### 訓練頻度

| 訓練種別 | 頻度 | 所要時間 | 対象者 |
|---------|------|---------|--------|
| テーブルトップ演習 | {{TABLETOP_FREQ}} | {{TABLETOP_DURATION}} | {{TABLETOP_PARTICIPANTS}} |
| フェイルオーバーテスト | {{FAILOVER_FREQ}} | {{FAILOVER_DURATION}} | {{FAILOVER_PARTICIPANTS}} |
| フルDR訓練 | {{FULL_DR_FREQ}} | {{FULL_DR_DURATION}} | {{FULL_DR_PARTICIPANTS}} |

### 訓練シナリオ

| シナリオ | 前提条件 | 期待結果 | 評価基準 |
|---------|---------|---------|---------|
| プライマリDB障害 | 自動フェイルオーバー有効 | DRサイトに自動切り替え | RTO < {{RTO_TARGET}} |
| リージョン全面障害 | 手動フェイルオーバー | DRサイトで全サービス稼働 | RTO < {{REGION_RTO_TARGET}} |
| {{CUSTOM_SCENARIO}} | {{SCENARIO_PREREQ}} | {{EXPECTED_RESULT}} | {{EVALUATION}} |

### 結果評価基準

| 指標 | 合格基準 | 不合格時のアクション |
|------|---------|-------------------|
| RTO 達成 | RTO 目標以内に復旧 | 手順見直し、自動化推進 |
| RPO 達成 | データ損失が RPO 以内 | 同期設定の見直し |
| 手順の正確性 | 手順書通りに実行可能 | 手順書の更新 |
| {{CUSTOM_METRIC}} | {{CUSTOM_CRITERIA}} | {{CUSTOM_ACTION}} |

### 改善アクション管理

| 訓練日 | 発見事項 | アクション | 担当 | 期限 | ステータス |
|--------|---------|-----------|------|------|----------|
| {{DRILL_DATE}} | {{FINDING}} | {{ACTION}} | {{OWNER}} | {{DEADLINE}} | {{STATUS}} |

---

## コスト見積もり

### バックアップコスト

| 項目 | サービス | 容量 | 月額コスト |
|------|---------|------|----------|
| DBバックアップ | {{SERVICE}} | {{CAPACITY}} | {{MONTHLY_COST}} |
| ファイルバックアップ | {{SERVICE}} | {{CAPACITY}} | {{MONTHLY_COST}} |
| アーカイブストレージ | {{SERVICE}} | {{CAPACITY}} | {{MONTHLY_COST}} |
| **小計** | | | **{{BACKUP_SUBTOTAL}}** |

### DRサイトコスト

| 項目 | サービス | 構成 | 月額コスト |
|------|---------|------|----------|
| コンピューティング（待機） | {{SERVICE}} | {{CONFIG}} | {{MONTHLY_COST}} |
| データベースレプリカ | {{SERVICE}} | {{CONFIG}} | {{MONTHLY_COST}} |
| データ転送 | {{SERVICE}} | {{TRANSFER_VOLUME}} | {{MONTHLY_COST}} |
| **小計** | | | **{{DR_SUBTOTAL}}** |

### 合計

| 項目 | 月額 | 年額 |
|------|------|------|
| バックアップ | {{BACKUP_SUBTOTAL}} | {{BACKUP_ANNUAL}} |
| DRサイト | {{DR_SUBTOTAL}} | {{DR_ANNUAL}} |
| **合計** | **{{TOTAL_MONTHLY}}** | **{{TOTAL_ANNUAL}}** |

---

## 関連ドキュメント

| ドキュメント | リンク |
|-------------|--------|
| インフラストラクチャ設計書 | [infrastructure.md](../03_architecture/infrastructure.md) |
| 運用手順書 | [operations.md](./operations.md) |
| インシデント対応計画 | [incident_response.md](./incident_response.md) |
| 可観測性設計書 | [observability_design.md](./observability_design.md) |

---

## 変更履歴

| 日付 | バージョン | 変更者 | 変更内容 |
|------|-----------|--------|----------|
| {{DATE}} | 1.0.0 | {{AUTHOR}} | 初版作成 |
