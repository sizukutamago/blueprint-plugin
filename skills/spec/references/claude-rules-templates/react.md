---
paths:
  - "src/**/*.tsx"
  - "src/interface/**"
---

# React コンポーネント規約

## コンポーネント設計

- **Props-based design**: API 呼び出しや副作用を props（`onSubmit`, `onSuccess` 等）で注入し、
  コンポーネント内部でフェッチしない（テスト容易性のため）
- コンポーネントは `src/interface/{feature-name}/` に配置する
- ページコンポーネント: `{FeatureName}Page.tsx`
- 再利用コンポーネント: `{FeatureName}/components/{ComponentName}.tsx`

## 命名規約

| 対象 | 規約 | 例 |
|------|------|-----|
| コンポーネント関数 | PascalCase | `TodoFormPage` |
| Props 型 | `{ComponentName}Props` | `TodoFormPageProps` |
| `data-testid` | kebab-case | `title-input`, `submit-button` |
| カスタムフック | `use` + PascalCase | `useTodoForm` |

## テスト容易性

- フォームの `submit` 先は `onSubmit?: (data: T) => Promise<void>` として props で受け取る
- 成功コールバックは `onSuccess?: () => void` として props で受け取る
- `data-testid` は Contract の `form.fields` のフィールド名に準拠する:
  - フィールド名 `title` → `data-testid="title-input"`
  - フィールド名 `description` → `data-testid="description-input"`

## アクセシビリティ

- ボタンは `aria-busy` で送信中状態を表現する（`disabled` と併用）
- エラーメッセージには `role="alert"` を付与する
- フォームフィールドには `<label>` を関連付ける

## 禁止パターン

- コンポーネント内での直接 `fetch` / `axios` 呼び出し
- `useEffect` での初期データ取得（ローダーパターンまたは RSC を使う）
- inline style（Tailwind クラスまたは CSS Modules を使う）
