# Phase: Implementation Standards

コーディング規約と開発環境設定を定義するフェーズ。
テスト設計は impl-test、運用設計は impl-ops が担当する。

## Contract (YAML)

```yaml
phase_id: "7a"
required_artifacts:
  - docs/03_architecture/architecture.md
  - docs/03_architecture/adr.md                    # optional

outputs:
  - path: docs/07_implementation/coding_standards.md
    required: true
  - path: docs/07_implementation/environment.md
    required: true

contract_outputs: []

quality_gates:
  - "コーディング規約が architecture.md の技術スタックと整合していること"
  - "環境設定に全環境（local/development/staging/production）が定義されていること"
```

## 入力要件

| 入力 | 必須 | 説明 |
|------|------|------|
| docs/03_architecture/architecture.md | ○ | 技術スタック情報 |
| docs/03_architecture/adr.md | △ | 技術選定理由（参考） |

## 出力ファイル

| ファイル | テンプレート | 説明 |
|---------|-------------|------|
| docs/07_implementation/coding_standards.md | references/coding_standards.md | コーディング規約 |
| docs/07_implementation/environment.md | references/environment.md | 環境設定 |

## ワークフロー

```
1. 技術スタック・アーキテクチャを読み込み
2. 技術スタックに応じたコーディング規約を生成
   - 命名規則（コンポーネント、変数、定数、テストファイル）
   - Git コミット規約（Conventional Commits）
   - ディレクトリ構成
   - コードスタイル（Lint/Formatter 設定含む）
3. 環境設定・デプロイ手順を生成
   - 各環境の定義（local, development, staging, production）
   - ブランチ戦略
   - CI/CD パイプライン概要
4. contract_outputs を出力
```

## コーディング規約

### 命名規則

| 対象 | 規則 |
|------|------|
| コンポーネント | PascalCase |
| ユーティリティ | camelCase |
| 定数 | UPPER_SNAKE |
| テスト | *.test.ts |

### Git 運用

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

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| architecture.md 不在 | P0 報告、architecture-skeleton フェーズの実行を要請 |
| 技術スタック未定義 | 一般的な規約を生成、P2 報告 |
