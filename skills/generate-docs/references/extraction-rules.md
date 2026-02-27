# 抽出ルール集

コードから設計書を生成する際の抽出ルール。
各設計書ファイルに対して「何を」「どこから」「どう」抽出するかを定義する。

## 03_architecture/architecture.md

### tech stack 抽出

| 抽出元 | 抽出方法 | 確信度 |
|--------|---------|--------|
| package.json dependencies | パッケージ名 → カテゴリ分類 | high |
| go.mod / Cargo.toml | 同上 | high |
| Dockerfile FROM | ベースイメージ → ランタイム特定 | high |
| tsconfig.json | TypeScript バージョン・設定 | high |

**カテゴリ分類ルール**:
- Framework: hono, express, fastify, next, nuxt, django, fastapi, gin
- ORM: prisma, drizzle, typeorm, sequelize, sqlalchemy
- DB: pg, mysql2, better-sqlite3, @prisma/client
- Auth: next-auth, passport, lucia, jose
- Test: vitest, jest, pytest, testing-library

### レイヤー構成推定

| パターン | 推定レイヤー | 確信度 |
|---------|------------|--------|
| src/routes/ or src/app/ | Router/Controller | medium |
| src/services/ or src/usecases/ | Business Logic | medium |
| src/repositories/ or src/db/ | Data Access | medium |
| src/models/ or src/entities/ | Domain Model | medium |
| src/middleware/ | Cross-cutting | medium |
| src/utils/ or src/lib/ | Shared Utilities | medium |

### 境界コンテキスト推定

`.blueprint/contracts/` のタイプ別ディレクトリから推定:
- `api/` → 公開 API 境界
- `external/` → 外部連携境界
- `files/` → バッチ/ファイル境界

## 03_architecture/adr.md

`.blueprint/decisions/` のファイルを集約:

```
抽出手順:
1. .blueprint/decisions/*.md を全読み込み
2. frontmatter の id, status, date を抽出
3. 本文の Context/Decision/Reason/Alternatives/Consequences を構造化
4. ADR 番号順にソート
```

確信度: **high**（ソースが明確）

## 04_data_structure/data_structure.md

### ORM モデルからの抽出

| ORM | 抽出元 | 抽出方法 |
|-----|--------|---------|
| Prisma | `prisma/schema.prisma` | model 定義 → エンティティ |
| Drizzle | `src/db/schema.ts` | テーブル定義 → エンティティ |
| TypeORM | `src/entities/*.ts` | @Entity デコレータ → エンティティ |
| Django | `models.py` | class Model → エンティティ |

### migration からの抽出

```
抽出手順:
1. migration ディレクトリ特定
2. 最新の migration を読み込み
3. CREATE TABLE / ALTER TABLE からスキーマ推定
```

確信度: ORM モデルあり → **high**、migration のみ → **medium**

## 05_api_design/api_design.md

### ルート定義からの抽出

| フレームワーク | 抽出パターン | 確信度 |
|-------------|------------|--------|
| Hono | `app.get/post/put/delete(path, handler)` | high |
| Express | `router.get/post(path, handler)` | high |
| Next.js App Router | `app/api/*/route.ts` の export | high |
| FastAPI | `@app.get/post(path)` デコレータ | high |
| OpenAPI spec | `openapi.yaml` or `swagger.json` | high |

### Contract との照合

```
照合手順:
1. .blueprint/contracts/api/*.contract.yaml の path を収集
2. コードのルート定義と照合
3. 一致 → Contract の仕様を設計書に反映
4. 不一致 → 不整合として報告
```

## 05_api_design/integration.md

`.blueprint/contracts/external/*.contract.yaml` を集約 + コードの外部 API クライアントを分析。

## 06_screen_design/

### コンポーネント抽出（React/Vue）

| 抽出元 | 抽出対象 | 確信度 |
|--------|---------|--------|
| src/pages/ or app/ | ページコンポーネント → 画面一覧 | medium |
| src/components/ | 共通コンポーネント → カタログ | medium |
| ルーティング設定 | パス → 画面遷移 | medium |

**注意**: 画面名・用途はコードだけでは不十分。ユーザーに確認が必要。

## 07_implementation/coding_standards.md

| 抽出元 | 抽出内容 | 確信度 |
|--------|---------|--------|
| biome.json / .eslintrc | lint ルール → コーディング規約 | high |
| .prettierrc | フォーマット規約 | high |
| tsconfig.json strict 設定 | 型安全性ポリシー | high |
| .editorconfig | インデント・改行規約 | high |
| 実際のコードパターン | 命名規則、ファイル構成規約 | medium |

## 07_implementation/test_strategy.md + test_plan.md

| 抽出元 | 抽出内容 | 確信度 |
|--------|---------|--------|
| vitest.config.ts / jest.config.ts | テスト設定 | high |
| tests/ ディレクトリ構造 | テスト構成（unit/integration/e2e） | high |
| テストファイル一覧 | テストケース数、カバレッジ | high |
| .blueprint/contracts/ | Contract ベースのテスト期待値 | high |

## 07_implementation/traceability_matrix.md

Contract の `links.implements` から FR → テスト のマッピングを構築:

```
構築手順:
1. 全 Contract の links.implements を収集 → FR-ID リスト
2. テストファイル内の Contract 参照を検索
3. FR → Contract → テスト の chain を構築
4. チェーンが切れている箇所を不整合として報告
```

## 07_implementation/operations.md + observability_design.md

| 抽出元 | 抽出内容 | 確信度 |
|--------|---------|--------|
| k8s manifests | リソース制限、レプリカ数 | high |
| Prometheus/Grafana 設定 | メトリクス定義 | high |
| alertmanager.yml | アラート設定 | high |
| .env.example | 環境変数一覧 | medium |
| README の運用セクション | 運用手順 | medium |

## 抽出不能時のフォールバック

コードから抽出できない情報への対応:

| 状況 | 対応 |
|------|------|
| 設定ファイルが見つからない | TODO マーカー + ユーザーに確認 |
| フレームワークが未知 | 汎用パターンで推定 + medium 確信度 |
| テストが存在しない | test_strategy.md に「テスト未実装」と記載 |
| インフラ設定なし | infrastructure.md に「ローカル開発環境のみ」と記載 |
| フロントエンドなし | 06_screen_design/ 全体をスキップ |
