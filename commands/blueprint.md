---
name: blueprint
description: Run the full workflow pipeline with Review Swarm quality gates. Automates /spec → /test-from-contract → implementation → /generate-docs.
---

# Blueprint Orchestrator Command

パイプラインをワンコマンドで自動実行する。

## 使用方法

```
/blueprint              # パイプライン実行（Smart Skip 適用）
/blueprint --resume     # 中断点から再開（任意ステージ対応）
/blueprint --force      # 全ステージ強制実行（Smart Skip 無視）
```

## パイプライン

```
Stage 1: /spec → Contract Review Gate
Stage 2: /test-from-contract → Test Review Gate
Stage 3: Implementation Pause（ユーザーが実装）→ Drift Gate
Stage 4: /generate-docs → Doc Review Gate
```

各ステージ後に **Review Swarm**（3 並列エージェント）が品質レビューを実行。
Gate 判定: P0=0 かつ P1≤1 → PASS、それ以外 → REVISE（最大 2 サイクル）。

## Smart Skip

既存の成果物を検出すると、該当ステージのスキップをユーザーに提案する。
スキップ時もレビューゲートは実行する。`--force` で全ステージ強制実行。

## 出力先

- `.blueprint/contracts/` — Contract YAML（Stage 1）
- `tests/contracts/` — TDD テスト（Stage 2）
- `docs/` — 設計書（Stage 4）
- `.blueprint/pipeline-state.yaml` — パイプライン状態

## 前提

- Git リポジトリ内であること
- テストフレームワークは自動検出（未検出時はユーザーに確認）

## 次のステップ

1. Stage 3 で一時停止後、Level 2 テストを実装して GREEN にする
2. `/blueprint --resume` で Stage 4 を再開
3. 完了後、P2 要対応リストを手動で修正

## 関連

- `/spec` — Contract YAML 生成（Stage 1 で実行）
- `/test-from-contract` — TDD テスト生成（Stage 2 で実行）
- `/generate-docs` — 設計書生成（Stage 4 で実行）
- orchestrator スキル（`core/orchestrator.md` でワークフロー定義）
