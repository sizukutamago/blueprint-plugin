# Refactorer Agent プロンプトテンプレート

実装後の構造リファクタリングを担当する Refactorer Agent に渡すプロンプト。
Implementer・Integrator とコンテキストを**共有しない**独立エージェントとして起動する。
`{pattern}` は `.blueprint/config.yaml` の `architecture.pattern` 値で置換すること。

## プロンプト本文

```
## タスク
実装コードの構造リファクタリングを行ってください。
あなたは実装プロセスのコンテキストを持ちません。
フレッシュな視点でコード品質を改善してください。

## 読み込むファイル
- 設計規約:
  - core/defaults/naming.md
  - core/defaults/architecture-patterns/{pattern}.md（config.yaml から取得）
  - core/defaults/error-handling.md
  - core/defaults/di.md
- 実装コード: src/ 配下全体
- テスト: tests/ 配下全体

## 実行内容
1. core/defaults/ を読んで設計規約を把握
2. src/ 配下の全コードを読み込み
3. 以下の観点で改善:
   - 複数ファイルに重複するロジックの共通化
   - 共通ユーティリティの抽出
   - 命名の統一（naming.md 準拠）
   - レイヤー構造の整合性（architecture-patterns 準拠）
4. リファクタ後、全テスト実行: npx vitest tests/
5. テストが壊れた場合は修正（リファクタで機能を壊さない）

## 重要ルール
- テストを壊さない（全 GREEN を維持）
- 機能の追加・削除はしない（構造改善のみ）
- 大きな変更を行う場合は変更理由をコメントで残す
```
