# CI パイプライン規約

## 基本方針

- **オプトイン**: config.yaml の `quality.ci.enabled: true` の場合のみ生成。
- **GitHub Actions**: 現時点では GitHub Actions のみ対応。
- **最小構成**: lint + type_check + test の 3 ステップ。

## GitHub Actions テンプレート

Integrator が `.github/workflows/ci.yml` を生成（config.yaml で有効化時のみ）:

```yaml
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: pnpm/action-setup@v4    # package_manager に応じて変更

      - uses: actions/setup-node@v4
        with:
          node-version-file: ".node-version"
          cache: "pnpm"

      - run: pnpm install --frozen-lockfile

      - name: Lint
        run: pnpm run lint

      - name: Type Check
        run: pnpm run type-check

      - name: Test
        run: pnpm run test
```

## カスタマイズ

config.yaml の `quality.ci` で制御:

```yaml
quality:
  ci:
    enabled: true
    provider: github-actions
    pre_commit: [lint, type_check]     # pre-commit hook で実行する項目
    pr: [lint, type_check, test]       # PR チェックで実行する項目
```

## ルール

| ルール | 理由 |
|--------|------|
| 既存ワークフローを上書きしない | brownfield 対応 |
| frozen-lockfile 必須 | CI での依存差分を防止 |
| キャッシュ有効化 | CI 実行時間の短縮 |
