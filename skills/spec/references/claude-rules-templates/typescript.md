---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---

# TypeScript 規約

## 型安全

- `any` 禁止。型が不明な場合は `unknown` を使い、型ガードで絞り込む
- 外部入力（API リクエスト、ファイル読み込み等）は必ず Zod 等でバリデーション後に型付けする
- `as` キャストは原則禁止。型ガード関数か Zod の `safeParse` で代替する
- `!`（non-null assertion）は原則禁止。`if` チェックか `??` で代替する

## 型定義のルール

- Zod スキーマから型を導出する: `type Foo = z.infer<typeof FooSchema>`
- 同じ構造の型を2箇所以上定義しない（domain/ の型を全層で共有する）
- export する関数には明示的な戻り値の型を付ける

## 命名規約

| 対象 | 規約 | 例 |
|------|------|-----|
| クラス / interface / type | PascalCase | `TodoRepository`, `CreateTodoInput` |
| 関数 / メソッド / 変数 | camelCase | `createTodo`, `findById` |
| 定数 | UPPER_SNAKE_CASE | `MAX_TITLE_LENGTH` |
| ファイル | kebab-case | `todo.repository.ts` |
| テストファイル | `{対象}.test.ts(x)` | `todo.repository.test.ts` |

## インポート順序

1. Node.js 組み込みモジュール
2. 外部パッケージ
3. 内部モジュール（`@/` エイリアス使用）

## 禁止パターン

- `console.log` を本番コードに残す（`console.error` / ロガーを使う）
- 空の `catch` ブロック（必ず処理を記述する）
- `Promise` を `await` せず放置する（`void` を付けるか `await` する）
