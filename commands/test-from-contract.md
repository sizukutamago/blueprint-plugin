---
name: test-from-contract
description: Generate TDD tests from Contract YAML files. Produces Level 1 (structure validation) and Level 2 (implementation stubs) tests.
---

# Test From Contract Command

Contract YAML から TDD テストコードを自動生成する。

## 使用方法

```
/test-from-contract
```

## ワークフロー

1. **コンテキスト読み込み** - `.blueprint/contracts/` スキャン、Contract 一覧化
2. **Contract 選択** - テスト生成対象の選択 + ユーザー承認
3. **テスト環境確認** - フレームワーク自動検出 + 出力先確認
4. **Level 1 テスト生成** - 構造検証テスト（即 GREEN）
5. **Level 2 テスト生成** - 実装検証テスト（RED スタブ）
6. **サマリー出力** - 生成ファイル一覧 + 次ステップ案内

## 出力先

- `tests/contracts/level1/` — 構造検証テスト（即 GREEN）
- `tests/contracts/level2/` — 実装検証テスト（RED スタブ）
- `tests/contracts/helpers/` — 共通ヘルパー

## 前提

- `/spec` で Contract が `.blueprint/contracts/` に定義済みであること

## 次のステップ

1. Level 1 テストを実行して全 GREEN を確認
2. Level 2 の RED スタブを 1 つずつ実装して GREEN にする
3. `/generate-docs` — 全テスト GREEN 後に設計書を後追い生成

## 関連

- `/spec` — Contract YAML 生成（上流）
- `/generate-docs` — 設計書生成（下流）
- test-from-contract スキル（`core/v5/test-from-contract.md` でワークフロー定義）
