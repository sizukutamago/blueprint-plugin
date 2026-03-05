# プロジェクト規約 — ベース

このプロジェクトは `.blueprint/contracts/` に Contract YAML で I/O 境界を定義している。
コードを変更する前に必ず対応する Contract を確認すること。

## アーキテクチャ依存ルール

```
domain ← usecase ← infra
domain ← usecase ← interface
```

- `domain/` は他のどの層にも依存しない（純粋なビジネスルール）
- `usecase/` は `domain/` のみに依存する
- `infra/` は `domain/` と `usecase/` に依存する
- `interface/` は `domain/` と `usecase/` に依存する
- 逆方向の依存（domain → usecase など）は禁止

## Contract との整合性

- 実装が Contract の `business_rules` を全て満たすこと
- Contract の `input` / `output` スキーマと実装の型が一致すること
- Contract に記載のないエラーコードを新たに追加する場合は Contract も更新すること

## エラー処理

- エラーは型で表現する（`throw new Error('文字列')` ではなく typed error class）
- 外部境界でのみ catch する（usecase / interface 層のエントリポイント）
- エラーメッセージはユーザー向け（ja）と開発者向け（ログ）を分ける

## レビュー観点チェックリスト

実装を行う際、以下を確認すること:

- [ ] Contract の全 `business_rules` が実装に反映されているか
- [ ] バリデーションが Contract の `constraints` / `validation_rules` と一致するか
- [ ] エラーレスポンスが Contract の `output.errors` と一致するか
- [ ] 新規ファイルが正しい層に配置されているか（依存ルール違反なし）
- [ ] テストが Level 1（構造）+ Level 2（実装）の両方をカバーしているか
