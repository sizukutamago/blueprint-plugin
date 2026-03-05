# blueprint-plugin

Contract-first の設計ワークフロープラグイン（Claude Code / Cursor 対応）

ブレスト → Contract YAML → TDD テスト → 実装 → 設計書生成のパイプラインを、**会話しながら自動生成**します。

## インストール

```bash
# マーケットプレイス経由
/plugin marketplace add sizukutamago/blueprint-plugin
/plugin install blueprint-plugin@blueprint-plugin

# ローカル開発（キャッシュをバイパス）
claude --plugin-dir /path/to/blueprint-plugin
```

## 使い方（3 ステップ）

```
1. プロジェクトのルートで Claude Code を起動

2. /blueprint と入力して Enter

3. 質問に答えていくと全パイプラインが自動実行される
```

## コマンド

| コマンド | 説明 |
|----------|------|
| `/blueprint` | 全パイプライン自動実行（推奨） |
| `/blueprint --resume` | 中断点から再開 |
| `/spec` | Stage 1: ブレスト → Contract YAML 生成 |
| `/test-from-contract` | Stage 2: Contract → TDD テスト生成 |
| `/implement` | Stage 3: テスト → 実装コード生成 |
| `/generate-docs` | Stage 4: コードから設計書を後追い生成 |

## 出力物

```
.blueprint/contracts/   # Contract YAML（仕様の Single Source of Truth）
tests/contracts/        # Level 1（構造検証）+ Level 2（実装検証）テスト
src/ or app/            # 実装コード（Layered / Clean / Flat）
docs/                   # 設計書（後追い生成）
```

## 詳細

→ [USAGE.md](./USAGE.md) — Contract の書き方、Review Gate、アーキテクチャ選択など

## ライセンス

MIT
