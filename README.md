# blueprint-plugin

Contract-first の設計ワークフロープラグイン（Claude Code / Cursor 対応）

ブレスト → Contract YAML → TDD テスト → 実装 → 設計書生成のパイプラインを、**会話しながら自動生成**します。
使い続けるほどログが蓄積され、プラグイン自体を改善する **Self-Improve** 機能も搭載。

## クイックスタート

### 1. インストール

```bash
# マーケットプレイス経由
/plugin marketplace add sizukutamago/blueprint-plugin
/plugin install blueprint-plugin@blueprint-plugin

# ローカル開発（キャッシュをバイパス）
claude --plugin-dir /path/to/blueprint-plugin
```

### 2. パイプライン実行

```bash
/blueprint       # プロジェクトルートで実行 → 質問に答えるだけで全自動
```

### 3. 出力物を確認

```
.blueprint/contracts/   # Contract YAML（仕様の Single Source of Truth）
tests/contracts/        # Level 1（構造検証）+ Level 2（実装検証）テスト
src/ or app/            # 実装コード（Layered / Clean / Flat）
docs/                   # 設計書（後追い生成）
```

## コマンド一覧

### パイプライン（メイン）

| コマンド | 説明 |
|----------|------|
| `/blueprint` | 全パイプライン自動実行（推奨） |
| `/blueprint --resume` | 中断点から再開 |
| `/blueprint --force` | 全ステージ強制再実行 |

### 個別ステージ

| コマンド | Stage | 説明 |
|----------|-------|------|
| `/spec` | 1 | ブレスト → Contract YAML 生成 |
| `/test-from-contract` | 2 | Contract → TDD テスト生成 |
| `/implement` | 3 | RED テスト → 実装コード生成 |
| `/generate-docs` | 4 | コードから設計書を後追い生成 |

### 自己改善

| コマンド | 説明 |
|----------|------|
| `/blueprint-improve` | 使用ログ分析 → 改善案提示 → PR 作成 |
| `/blueprint-improve --stats` | 統計レポートのみ表示 |
| `/blueprint-improve --cleanup` | 期限切れログ（90日超過）の削除 |

## Self-Improve の仕組み

```
パイプライン実行 → SessionEnd Hook が自動でログ収集
                     ↓
              ~/.claude/blueprint-logs/ に蓄積
                     ↓
              /blueprint-improve で分析 → 改善 PR を作成
```

- ログはローカルのみ保存（外部送信なし）
- 未分析ログが 10 件以上で起動時に通知

## 詳細ガイド

[USAGE.md](./USAGE.md) — 各ステージの手順、Contract の書き方、Review Gate、Self-Improve の詳細

## ライセンス

MIT
