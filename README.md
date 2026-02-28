# blueprint-plugin

Contract-first の設計ワークフロープラグイン（Claude Code / Cursor 対応）

ブレスト → Contract YAML → TDD テスト → 実装 → 設計書生成のパイプラインを提供します。
Review Swarm による品質ゲート（P0/P1/P2 判定）付き。

## インストール

### マーケットプレイス経由

```bash
/plugin marketplace add sizukutamago/blueprint-plugin
/plugin install blueprint-plugin@blueprint-plugin
```

### ローカル開発

```bash
claude --plugin-dir /path/to/blueprint-plugin
```

## コマンド

| コマンド | 説明 |
|----------|------|
| `/blueprint` | 全パイプライン自動実行（推奨） |
| `/blueprint --resume` | 中断点から再開 |
| `/spec` | Stage 1: ブレスト → Contract YAML 生成 |
| `/test-from-contract` | Stage 2: Contract → TDD テスト生成 |
| `/implement` | Stage 3: Contract + RED テスト → 実装コード生成 |
| `/generate-docs` | Stage 4: コードから設計書を後追い生成 |

## パイプライン

```
Stage 1: /spec（対話的）→ Contract Review Gate
Stage 2: /test-from-contract（準自動）→ Test Review Gate
Stage 3: /implement（承認 2 回）→ Code Review Gate
Stage 4: /generate-docs（準自動）→ Doc Review Gate
```

各 Review Gate で 3 エージェントが並列レビュー。Gate 判定: P0=0 かつ P1≤1 → PASS。

## スキル一覧

| スキル | 説明 |
|--------|------|
| orchestrator | パイプラインオーケストレータ（Review Swarm 統合） |
| spec | ブレスト + Contract YAML 生成 |
| test-from-contract | Contract → Level 1/2 TDD テスト生成 |
| implement | Contract + RED テスト → 実装コード生成（Implementers/Integrator/Refactorer） |
| generate-docs | 実装コードから設計書を後追い生成 |
| gap-analysis | 既存システム分析（brownfield プロジェクト用） |
| research | 技術調査（WebSearch/WebFetch） |
| context-compressor | コンテキスト圧縮 |

## 出力構造

設計書は `docs/` 配下に生成:

```
docs/
├── 03_architecture/         # アーキテクチャ設計
├── 04_data_structure/       # データ構造定義
├── 05_api_design/           # API 仕様書
├── 06_screen_design/        # 画面設計書（フロントエンドがある場合）
├── 07_implementation/       # 実装標準 + テスト設計 + 運用設計
└── 08_review/               # レビュー結果
```

Contract は `.blueprint/contracts/` に格納。詳細は `core/output-structure.md` 参照。

## Cursor での使用

`.cursor/rules/` に 6 つのルールファイルが自動適用:
- `blueprint-always.mdc` — 共通規約
- `blueprint-orchestrator.mdc` — パイプライン全体制御
- `blueprint-spec.mdc` / `blueprint-test-from-contract.mdc` / `blueprint-implement.mdc` / `blueprint-generate-docs.mdc`

## アップデート

```bash
./scripts/plugin-update.sh
./scripts/plugin-update.sh --bump  # バージョンバンプ + プッシュ
```

## ライセンス

MIT License - 詳細は [LICENSE](./LICENSE) を参照
