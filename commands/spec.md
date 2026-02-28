---
name: spec
description: Create I/O boundary contracts through brainstorming. Generates Contract YAML files in .blueprint/ directory.
---

# Spec Command

ブレインストーミングを通じて Contract YAML を生成する。

## 使用方法

```
/spec
```

## ワークフロー

1. **コンテキスト読み込み** - `.blueprint/` の初期化 or 既存読み込み
2. **スコープ確認** - 何を作る/変更するか
3. **ブレインストーミング** - ビジネスルール深掘り（最大 10 質問）
4. **Contract 一覧合意** - タイプ判定 + 依存関係 ★承認必須★
5. **Contract YAML 生成** - テンプレートベースで構造化
6. **副産物生成** - concepts/ と decisions/ への書き出し
7. **サマリー出力** - 生成ファイル一覧 + 次ステップ案内

## 出力先

- `.blueprint/contracts/` — Contract YAML
- `.blueprint/concepts/` — ドメイン概念メモ
- `.blueprint/decisions/` — 設計判断記録

## 次のステップ

- `/test-from-contract` — Contract から TDD テストを自動生成
- `/generate-docs` — 実装後にコードから設計書を生成

## 関連

- spec スキル（`core/spec.md` でワークフロー定義）
