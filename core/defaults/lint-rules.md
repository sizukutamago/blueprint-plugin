# Lint / Format 規約

## 基本方針

- **Biome 推奨**: 設定が少なく高速。config.yaml で `lint: biome` がデフォルト。
- **ESLint 対応**: brownfield プロジェクトで既存 ESLint がある場合はそれを尊重。
- **Implementer が設定ファイルを生成**: config.yaml の quality.lint に基づく。

## Biome 設定（推奨）

Implementer が生成する `biome.json`:

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

## ESLint 設定（brownfield 用）

既存の ESLint 設定がある場合、Implementer は設定ファイルを **生成しない**。
Implementer は既存ルールに従って実装する。

## ルール

| ルール | 理由 |
|--------|------|
| 既存設定を上書きしない | brownfield プロジェクトの設定を尊重 |
| any 禁止 | 型安全性の確保 |
| 認知的複雑度 ≤ 15 | 巨大関数の防止（Code Quality Checker でも検出） |
| import 順序の自動整理 | 一貫性の確保 |
