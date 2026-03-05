# Implementer Agent プロンプトテンプレート

Contract 単体の実装を担当する Implementer Agent に渡すプロンプトのテンプレート。
`{placeholder}` は呼び出し時に実際の値で置換すること。

## プロンプト本文

```
## タスク
Contract CON-{name} の実装を行い、RED テストを GREEN にしてください。
ディレクトリ・ファイルの作成から実装まで全て行ってください。

## Contract 情報（インライン）
- Contract ID: CON-{name}
- Type: {type}  (api | external | file | internal | screen)
- Tech Stack: {framework} + {validation} + {orm}
- Architecture: {pattern}
- 担当エンティティ: {entity}
- screen の場合は: screen_type={screen_type}, frontend.framework={frontend_framework}

## 読み込むファイル
- Contract YAML: .blueprint/contracts/{type}/{name}.contract.yaml
- RED テスト（api/external/file/internal）: tests/contracts/level2/CON-{name}.test.ts
- RED テスト（screen）: tests/ui/{screen-name}/{ScreenName}Page.test.tsx
- 命名規約: core/defaults/naming.md
- アーキテクチャ: core/defaults/architecture-patterns/{pattern}.md
- エラー処理: core/defaults/error-handling.md
- DI: core/defaults/di.md
- バリデーション: core/defaults/validation-patterns.md

## 実装手順
1. 上記ファイルを全て読み込む
2. Contract の implementation.flow がある場合はその順序で実装
   flow がない場合は一括で実装
3-a. api/external/file/internal の場合: 作成するファイル（{entity} 名前空間配下のみ）:
   - 型定義（Contract input/output から導出）
   - バリデーションスキーマ
   - ビジネスロジック（business_rules は TDD: ユニットテストを先に書く）
   - Repository interface + 実装
   - ルートファイル（method + path からルート定義）
3-b. screen の場合: 作成するファイル（src/interface/{screen-name}/ 配下のみ）:
   - {ScreenName}Page.tsx（ページコンポーネント）
   - components/ 配下のサブコンポーネント
   - validation_rules → フロントエンドバリデーション実装
4. ユニットテストは tests/unit/{entity}/ に配置（api/external/file/internal のみ）
5. テスト実行:
   - api/external/file/internal: npx vitest tests/contracts/level2/CON-{name}.test.ts
   - screen: {frontend_test_runner} tests/ui/{screen-name}/
6. 全テスト GREEN になるまで修正を続ける

## 重要ルール
- app.ts や DI container など共有ファイルは作成しない（Integrator が担当）
- 自分の名前空間（{entity} または src/interface/{screen-name}/）配下のファイルのみ作成・編集
- テストが GREEN にならない場合、同じエラーが 3 回連続したらその旨を報告
- 勝手にスキップしない
```
