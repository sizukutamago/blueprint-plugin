---
paths:
  - "tests/ui/**"
  - "**/*.test.tsx"
---

# @testing-library テスト規約

## クエリ優先順位（高→低）

1. `getByRole` — アクセシビリティロールで取得（最優先）
2. `getByLabelText` — ラベルテキストで取得
3. `getByPlaceholderText` — プレースホルダーで取得
4. `getByText` — テキスト内容で取得
5. `getByTestId` — `data-testid` で取得（最終手段）

`getByTestId` は Contract の `form.fields` から導出したフィールド名のみ使用可。

## イベント操作

- `userEvent`（`@testing-library/user-event`）を使う。`fireEvent` は原則禁止
- テスト冒頭で `const user = userEvent.setup()` を初期化する

```typescript
// Good
const user = userEvent.setup()
await user.type(screen.getByTestId('title-input'), 'テスト')
await user.click(screen.getByRole('button', { name: '送信' }))

// Bad
fireEvent.change(input, { target: { value: 'テスト' } })
```

## 非同期アサーション

- DOM の変化を待つ場合は `waitFor` を使う
- `waitFor` 内には1つのアサーションのみ記述する

```typescript
// Good
await waitFor(() => {
  expect(screen.getByText('タイトルは必須です')).toBeInTheDocument()
})

// Bad: waitFor 内に複数アサーション
await waitFor(() => {
  expect(a).toBe(...)
  expect(b).toBe(...)
})
```

## テスト構成

- `describe` ブロックは Contract の ID とセクション（VR-001〜 / BR-001〜）に対応させる
- テスト名は Contract の `validation_rules[].id` または `business_rules[].id` を含める:
  - `VR-001: title が空のまま送信すると「タイトルは必須です」が表示される`
  - `BR-002: 送信中はボタンが無効化される`

## モック

- `vi.fn()` でコールバック props をモック
- 送信処理は `Promise` を返す関数でモックし、解決タイミングを制御できるようにする:

```typescript
let resolveSubmit!: () => void
const mockOnSubmit = vi.fn(
  () => new Promise<void>((resolve) => { resolveSubmit = resolve })
)
```

## beforeEach

- 各テストの前に `vi.resetAllMocks()` を呼ぶ
