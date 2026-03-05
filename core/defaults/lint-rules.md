# Lint / Format 規約

## 基本方針

- **oxlint デフォルト**: 設定ファイル不要・高速。プロジェクトに lint 設定がない場合に自動セットアップ。
- **既存設定を尊重**: `biome.json` / `.eslintrc*` / `oxlint.json` が存在する場合は生成しない。
- **フォーマットは Biome**: lint は oxlint、フォーマットは biome（独立して共存可能）。

## lint 設定の検出と判定

| 検出ファイル | 使用ツール | 対応 |
|------------|----------|------|
| `biome.json` | Biome | 既存設定を使う（生成しない） |
| `.eslintrc*` / `eslint.config.*` | ESLint | 既存設定を使う（生成しない） |
| `oxlint.json` / `.oxlintrc.json` | oxlint | 既存設定を使う（生成しない） |
| どれもない | oxlint | 自動セットアップ（以下の手順） |

## oxlint セットアップ（lint 設定が存在しない場合のデフォルト）

### インストール

```bash
npm add -D oxlint
# フォーマットも必要な場合
npm add -D @biomejs/biome
```

### `.oxlintrc.json`

```json
{
  "$schema": "https://cdn.jsdelivr.net/npm/oxlint@latest/configuration_schema.json",
  "plugins": ["typescript", "unicorn", "import"],
  "rules": {
    "no-unused-vars": "error",
    "no-console": "warn",
    "typescript/no-explicit-any": "error",
    "typescript/no-unused-vars": "error",
    "import/no-cycle": "error",
    "import/no-duplicates": "error"
  },
  "categories": {
    "correctness": "error",
    "suspicious": "warn"
  }
}
```

### `package.json` scripts

```json
{
  "scripts": {
    "lint": "oxlint --import-plugin --tsconfig ./tsconfig.json src/ tests/",
    "lint:fix": "oxlint --fix --import-plugin --tsconfig ./tsconfig.json src/ tests/",
    "format": "biome format --write .",
    "check": "npm run lint && npm run format"
  }
}
```

### 実行コマンド詳細

```bash
# 基本（高速チェック）
npx oxlint src/

# TypeScript 型情報あり + import 解析（推奨）
npx oxlint --import-plugin --tsconfig ./tsconfig.json -D suspicious src/ tests/

# 自動修正
npx oxlint --fix --import-plugin --tsconfig ./tsconfig.json src/ tests/
```

**主要フラグ**:

| フラグ | 効果 |
|--------|------|
| `--import-plugin` | import の循環依存・重複を検出 |
| `--tsconfig ./tsconfig.json` | TypeScript パスエイリアス解決 |
| `-D suspicious` | 疑わしいコード（重複条件、到達不能コード等）を error 扱い |
| `-D correctness` | 明らかに誤ったコードを error 扱い（デフォルト有効）|
| `-W pedantic` | 厳格ルール（warn レベル）|

## Biome 設定（フォーマット専用 / lint が biome の場合）

lint と format を両方 biome で行う場合は以下を使用:

```json
{
  "$schema": "https://biomejs.dev/schemas/1.9.0/schema.json",
  "organizeImports": { "enabled": true },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true,
      "complexity": {
        "noExcessiveCognitiveComplexity": {
          "level": "warn",
          "options": { "maxAllowedComplexity": 15 }
        }
      },
      "suspicious": {
        "noExplicitAny": "error"
      }
    }
  },
  "formatter": {
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 100
  }
}
```

## ルール

| ルール | 理由 |
|--------|------|
| 既存設定を上書きしない | brownfield プロジェクトの設定を尊重 |
| `any` 禁止 | 型安全性の確保 |
| 認知的複雑度 ≤ 15 | 巨大関数の防止（Code Quality Checker でも検出）|
| import 循環禁止 | レイヤー構造の整合性確保 |
| import 重複禁止 | 不要な重複排除 |
