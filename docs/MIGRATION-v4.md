# v4.0 移行ガイド

## 変更概要

v4.0 で設計仕様を `core/` ディレクトリに分離し、Claude Code と Cursor の両対応を実現しました。

## 既存ユーザーへの影響

### Claude Code ユーザー

**影響: 低**。既存の `/design-docs` コマンドはそのまま動作します。

- `skills/*/SKILL.md` は `core/phases/*.md` を参照する薄いラッパーに変換済み
- SendMessage フォーマット、agent-teams プロトコルに変更なし
- `skills/shared/references/project-context.yaml` は `core/blackboard-schema.yaml` に移管（旧ファイルも残存）

### Cursor ユーザー

**新規対応**。`.cursor/rules/` が自動適用されます。

1. プロジェクトに `.cursor/rules/` が含まれていれば自動で動作
2. 「設計ドキュメントを作成して」で `blueprint-orchestrator.mdc` が発火
3. `workflow-state/task_plan.md` でフェーズ進捗を追跡

## 主要な構造変更

| Before (v3.x) | After (v4.0) | 影響 |
|---------------|-------------|------|
| `skills/*/SKILL.md` に仕様全体 | `core/phases/*.md` に仕様、SKILL.md は薄ラッパー | 後方互換（SKILL.md は残存） |
| `skills/shared/references/project-context.yaml` | `core/blackboard-schema.yaml` | 旧ファイルも残存 |
| Cursor 非対応 | `.cursor/rules/*.mdc` で対応 | 新規追加（既存に影響なし） |

## profile 未設定時のデフォルト動作

v4.0 で統一: `sla_tier: basic`, `has_migration: false` として扱う。
条件付きファイル（backup_restore_dr.md, migration_plan.md）はスキップ。
profile の未設定自体を P2 として記録。

## Contract YAML

各 `core/phases/*.md` に `## Contract (YAML)` セクションが追加されました。
これは機械可読な仕様定義で、将来的にスキーマ lint ツールで検証可能にする意図です。

## Blackboard キーパス

v4.0 では `blackboard.decisions.*` を正規パスとして統一しました。
contract_outputs で `decisions.*` と記述した場合、統合ステップで `blackboard.decisions.*` に正規化されます。
