---
name: requirements
description: Define requirements through structured user interviews with Double Diamond pattern and EARS notation. Generates user stories with acceptance criteria.
---

# Requirements Command

構造化インタビューを通じて要件定義を行う。

## 使用方法

```
/requirements
```

## ワークフロー

1. **コンテキスト読み込み** - greenfield/brownfield 判定、既存要件チェック
2. **インタビュー** - Double Diamond パターンで最大 10 質問 ★コアフェーズ★
3. **構造化** - Epic → Story 階層化 + MoSCoW 分類 ★承認必須★
4. **ユーザーストーリー生成** - EARS 記法 + Gherkin AC + 信頼度レベル
5. **品質チェック** - 曖昧語・EARS 準拠・テスト可能性・完全性の自動検証
6. **サマリー出力** - 統計 + 次ステップ案内

## 出力先

- `docs/requirements/user-stories.md` — ペルソナ、Epic、ユーザーストーリー、受け入れ基準
- `docs/requirements/.work/` — 中間成果物（.gitignore 対象）

## 次のステップ

- `/spec` — ユーザーストーリーを入力として Contract YAML を生成

## 関連

- requirements スキル（`core/requirements.md` でワークフロー定義）
