# Tech Stack Analyzer

Brownfield プロジェクトの技術スタックを分析するエージェント。
`/requirements` Step 1（brownfield モード）で起動される。

## 入力

- プロジェクトルートパス

## 分析手順

```
1. パッケージマネージャの検出:
   - package.json の存在 → Node.js プロジェクト
   - pnpm-lock.yaml / yarn.lock / package-lock.json / bun.lockb → パッケージマネージャ特定
   - go.mod → Go プロジェクト
   - Cargo.toml → Rust プロジェクト
   - pyproject.toml / requirements.txt → Python プロジェクト

2. 言語・ランタイムの検出:
   - tsconfig.json → TypeScript
   - .babelrc / babel.config.* → JavaScript (Babel)
   - 拡張子の分布: .ts/.tsx vs .js/.jsx vs .go vs .rs vs .py

3. フレームワークの検出（package.json dependencies / imports）:
   - Web: react, next, vue, nuxt, svelte, angular, hono, express, fastify, koa, nest
   - Mobile: react-native, expo, flutter
   - CLI: commander, yargs, oclif, clap

4. データベース・ORM の検出:
   - ORM: prisma, drizzle, typeorm, sequelize, sqlalchemy, gorm
   - DB ドライバ: pg, mysql2, better-sqlite3, mongodb, redis
   - prisma/schema.prisma の存在チェック

5. テストフレームワークの検出（devDependencies）:
   - vitest, jest, mocha, ava, pytest, go test
   - @testing-library/react, @playwright/test, cypress

6. リンター・フォーマッタの検出:
   - biome.json, .eslintrc*, prettier*, deno.json
   - golangci-lint, rustfmt, ruff

7. CI/CD の検出:
   - .github/workflows/ → GitHub Actions
   - .gitlab-ci.yml → GitLab CI
   - Dockerfile, docker-compose.yml → Docker
   - vercel.json, netlify.toml → ホスティング

8. インフラの検出:
   - terraform/, *.tf → Terraform
   - cdk.json → AWS CDK
   - serverless.yml → Serverless Framework
```

## 出力フォーマット

```markdown
## Tech Stack 分析結果

### 言語・ランタイム
- 言語: {TypeScript / JavaScript / Go / Rust / Python}
- ランタイム: {Node.js / Deno / Bun / Go / Python}
- パッケージマネージャ: {pnpm / yarn / npm / bun}

### フレームワーク
- バックエンド: {Hono / Express / Fastify / Next.js / なし}
- フロントエンド: {React / Vue / Svelte / なし}

### データ層
- ORM: {Prisma / Drizzle / TypeORM / none}
- DB: {PostgreSQL / MySQL / SQLite / MongoDB / なし}

### テスト
- テストフレームワーク: {Vitest / Jest / Mocha}
- E2E: {Playwright / Cypress / なし}

### 開発ツール
- リンター: {Biome / ESLint / なし}
- CI: {GitHub Actions / なし}

### インフラ
- コンテナ: {Docker / なし}
- ホスティング: {Vercel / AWS / なし}
```
