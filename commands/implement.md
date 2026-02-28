---
name: implement
description: Implement code from Contract YAML and RED tests. Runs Scaffolder, Implementers, and Integrator to produce working code with all tests GREEN.
---

# Implement Command

Contract YAML と RED テストから実装コードを生成する。

## 使用方法

```
/implement
```

## ワークフロー

1. **コンテキスト読み込み** - config.yaml + Contract + RED テスト確認
2. **実装計画** - depends_on でトポロジカルソート、並列グループ算出
3. **Scaffolder** - ディレクトリ構造 + 型定義 + 雛形生成 ★承認 1★
4. **Implementers** - Contract 単位で RED→GREEN（並列実行）
5. **Integrator** - 全テスト実行 + 品質チェック ★承認 2★
6. **pipeline-state 更新** - 進捗記録

## 出力先

- `src/` — 実装コード（architecture pattern に応じた構造）
- `biome.json` 等 — Lint/Format 設定（オプション）
- `.github/workflows/` — CI 設定（オプション）

## 前提

- `/spec` で config.yaml と Contract が `.blueprint/` に定義済みであること
- `/test-from-contract` で Level 2 テストが `tests/contracts/` に生成済みであること

## 次のステップ

- Code Review Gate（`/blueprint --resume` で自動実行）
- `/generate-docs` — 設計書の後追い生成

## 関連

- `/spec` — Contract YAML 生成（上流）
- `/test-from-contract` — RED テスト生成（上流）
- `/generate-docs` — 設計書生成（下流）
- implement スキル（`core/implement.md` でワークフロー定義）
