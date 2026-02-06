---
name: implementation
description: This skill should be used when the user asks to "create coding standards", "setup development environment", "design test strategy", "write operations runbook", "define deployment process", or "document implementation guidelines". Creates implementation preparation documents.
version: 2.0.0
---

# Implementation Standards Skill

コーディング規約と開発環境設定を作成するスキル。
テスト設計は impl-test、運用設計は impl-ops が担当する。

**実行タイミング**: Wave C（impl-test, impl-ops と並列）

## 前提条件

| 条件 | 必須 | 説明 |
|------|------|------|
| docs/03_architecture/architecture.md | ○ | 技術スタック情報 |
| docs/03_architecture/adr.md | △ | 技術選定理由 |

## 出力ファイル

| ファイル | テンプレート | 説明 |
|---------|-------------|------|
| docs/07_implementation/coding_standards.md | {baseDir}/references/coding_standards.md | コーディング規約 |
| docs/07_implementation/environment.md | {baseDir}/references/environment.md | 環境設定 |

## 依存関係

| 種別 | 対象 |
|------|------|
| 前提スキル | architecture, design-detail |
| 並列スキル | impl-test, impl-ops（Wave C） |
| 後続スキル | review |

## ワークフロー

```
1. 技術スタック・アーキテクチャを読み込み
2. コーディング規約を生成
3. 環境設定・デプロイ手順を生成
```

## コーディング規約

### 命名規則

| 対象 | 規則 |
|------|------|
| コンポーネント | PascalCase |
| ユーティリティ | camelCase |
| 定数 | UPPER_SNAKE |
| テスト | *.test.ts |

### Git運用

| type | 用途 |
|------|------|
| feat | 新機能 |
| fix | バグ修正 |
| docs | ドキュメント |
| refactor | リファクタ |
| test | テスト |
| chore | その他 |

## 環境設定

| 環境 | ブランチ |
|------|---------|
| local | - |
| development | develop |
| staging | release/* |
| production | main |

## SendMessage 完了報告

タスク完了時に以下の YAML 形式で Lead に SendMessage を送信する:

```yaml
status: ok
severity: null
artifacts:
  - docs/07_implementation/coding_standards.md
  - docs/07_implementation/environment.md
contract_outputs: []
open_questions: []
blockers: []
```

**注意**: project-context.yaml には直接書き込まない（Aggregator の責務）。

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| architecture.md 不在 | Phase 3 の実行を促す |
| 技術スタック未定義 | 一般的な規約を生成、P2 として記録 |
