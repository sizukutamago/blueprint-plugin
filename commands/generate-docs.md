---
name: generate-docs
description: Generate design documents from existing code. Analyzes source code and produces v4-compatible documentation in docs/ directory.
---

# Generate Docs Command

実装済みコードから設計書を後追い生成する。

## 使用方法

```
/generate-docs
```

## ワークフロー

1. **プロジェクト分析** - tech stack 推定、ソースコード構造スキャン
2. **自動抽出** - コードから設計情報を抽出（グループ A → B）
3. **補足入力** - コードだけでは不足する情報をユーザーに確認（グループ C）
4. **トレーサビリティ検証** - Contract → テスト → 実装 → 設計書 の整合性チェック
5. **レビュー + サマリー** - v4 相当の整合性チェック + 確信度レポート

## 出力先

すべてのドキュメントは `docs/` ディレクトリに生成される（v4 互換構造）。

## 前提

- `/spec` で Contract が定義済みだとトレーサビリティ検証が有効
- `.blueprint/` がなくても設計書生成は可能（トレーサビリティはスキップ）

## 関連

- `/spec` — Contract YAML 生成（上流）
- `/test-from-contract` — Contract からテスト生成（上流）
- generate-docs スキル（`core/v5/generate-docs.md` でワークフロー定義）
