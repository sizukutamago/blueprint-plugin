---
name: design-docs
description: Run the full design document workflow using agent-teams. Use when creating complete system design documentation for new projects.
---

# Design Docs Command

システム設計書一式を生成するコマンド。
design-doc-orchestrator スキルを起動し、agent-teams による 2-wave 並列実行で設計プロセスを実行する。

## 使用方法

```
/design-docs
```

## ワークフロー

1. **Requirements** - `web-requirements` スキルで要件定義（外部プラグイン）★承認必須★
1.5. **Tech Stack** - 技術スタック確認（カテゴリ別ヒアリング）★承認必須★
2. **Wave A（並列）** - Architecture Skeleton + Database + Design Inventory
3. **Aggregator** - Wave A 統合
4. **Wave B（並列）** - API + Architecture Detail
5. **Aggregator** - Wave B 統合
6. **Post-B** - Design Detail（画面詳細）
7. **Wave C（並列）** - Implementation Standards + Test Design + Operations Design
8. **Review** - 整合性チェック・Gate 判定（Level 5 運用準備チェック含む）

## 出力先

すべてのドキュメントは `docs/` ディレクトリに生成される。

## 個別スキル実行

単独フェーズの実行も可能:
  - `/architecture` - アーキテクチャ設計
  - `/database` - データ構造設計
  - `/api` - API設計
  - `/design` - 画面設計
  - `/implementation` - 実装準備
  - `/review` - レビュー

## 関連

- design-doc-orchestrator スキル（`references/team-mode.md` で実行プロトコル定義）
- architecture, database, api, design, implementation, design-doc-reviewer エージェント
