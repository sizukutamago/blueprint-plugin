---
name: blueprint-improve
description: Analyze blueprint usage logs and generate improvement PRs. Self-improvement loop for the blueprint plugin.
---

# Blueprint Improve Command

blueprint パイプラインの使用ログを分析し、改善案を PR として提出する。

## 使用方法

```
/blueprint-improve
/blueprint-improve --stats
/blueprint-improve --cleanup
```

## オプション

| オプション | 説明 |
|-----------|------|
| (なし) | 分析 → 改善案提示 → ユーザー承認 → PR 作成 |
| `--stats` | 統計レポートのみ表示（PR 作成しない） |
| `--cleanup` | 期限切れログ（TTL 超過）の削除 |

## ワークフロー

1. **ログ読み込み** — `~/.claude/blueprint-logs/` の未分析ログを集計
2. **パターン分析** — recurring findings、common errors、user corrections を検出
3. **改善案提示** — 優先度付きの改善案をユーザーに提示
4. **ユーザー承認** — 採用/棄却を選択
5. **PR 作成** — `gh pr create --repo sizukutamago/blueprint-plugin`
6. **トリアージ更新** — 分析済みログのステータスを更新

## データソース

- `~/.claude/blueprint-logs/bl-*.yaml` — SessionEnd Hook で自動収集
- ログは blueprint パイプライン実行時のみ収集される

## 関連

- self-improve スキル（`core/self-improve.md` で分析ポリシー定義）
- SessionEnd Hook（`hooks/hooks.json` でログ収集定義）
