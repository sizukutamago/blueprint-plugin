# blueprint-plugin

Claude Code プラグイン - agent-teams による設計ドキュメント生成ワークフロー

IPA共通フレーム準拠の設計書一式を、agent-teams の3-wave並列実行で自動生成します。

## インストール

### マーケットプレイス経由

```bash
# マーケットプレイスを追加
/plugin marketplace add sizukutamago/blueprint-plugin

# プラグインをインストール
/plugin install blueprint-plugin@blueprint-plugin
```

### ローカル開発

```bash
claude --plugin-dir /path/to/blueprint-plugin
```

## 前提条件

- [dev-tools-plugin](https://github.com/sizukutamago/dev-tools-plugin) の `web-requirements` スキルが Phase 1-2（要件定義）に必要
- agent-teams 機能: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`

## コマンド

| コマンド | 説明 |
|----------|------|
| `/design-docs` | 全フェーズを agent-teams で実行（推奨） |

## スキル一覧

### オーケストレーション

| スキル | 説明 |
|--------|------|
| design-doc-orchestrator | 3-wave 並列実行のオーケストレータ |
| wave-aggregator | Wave 統合・Blackboard 更新（単一ライター） |
| context-compressor | コンテキスト圧縮（200k→70k tokens） |

### Wave A（並列）

| スキル | Phase | 説明 |
|--------|-------|------|
| architecture-skeleton | 3a | 技術選定・ADR・NFRポリシー |
| database | 4 | データ構造・エンティティ定義 |
| design-inventory | 6a | 画面棚卸し・遷移図 |

### Wave B（並列）

| スキル | Phase | 説明 |
|--------|-------|------|
| api | 5 | REST API・外部連携仕様 |
| architecture-detail | 3b | セキュリティ・インフラ・キャッシュ |

### Post-B

| スキル | Phase | 説明 |
|--------|-------|------|
| design-detail | 6b | 画面詳細・コンポーネントカタログ |

### Wave C（並列）

| スキル | Phase | 説明 |
|--------|-------|------|
| implementation | 7a | コーディング規約・開発環境 |
| impl-test | 7b | テスト戦略・計画・トレーサビリティ |
| impl-ops | 7c | 可観測性・インシデント対応・DR |

### レビュー

| スキル | Phase | 説明 |
|--------|-------|------|
| design-doc-reviewer | 8 | 整合性チェック・Gate判定（Level 5 運用準備） |

### ユーティリティ

| スキル | 説明 |
|--------|------|
| gap-analysis | 既存システム分析（brownfield プロジェクト用） |
| research | 技術調査（WebSearch/WebFetch） |

## エージェント

| エージェント | 説明 |
|-------------|------|
| architecture | アーキテクチャ設計 |
| database | データ構造設計 |
| api | API設計 |
| design | 画面設計 |
| implementation | 実装準備 |
| design-doc-reviewer | レビュー・Gate判定 |

## 出力構造

すべての設計書は `docs/` ディレクトリに生成されます:

```
docs/
├── project-context.yaml    # Blackboard（Aggregator のみ書き込み）
├── requirements/            # 要件定義（web-requirements 出力）
├── 03_architecture/         # アーキテクチャ設計
├── 04_data_structure/       # データ構造定義
├── 05_api_design/           # API仕様書
├── 06_screen_design/        # 画面設計書
├── 07_implementation/       # 実装標準 + テスト設計 + 運用設計
└── 08_review/               # レビュー結果
```

## アップデート

```bash
# キャッシュクリア + 再インストール
./scripts/plugin-update.sh

# バージョンバンプ + プッシュ + 再インストール
./scripts/plugin-update.sh --bump
```

## ライセンス

MIT License - 詳細は [LICENSE](./LICENSE) を参照
