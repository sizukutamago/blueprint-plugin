#!/bin/bash
# notify_pending_logs.sh - SessionStart hook: 未分析ログの通知
#
# ~/.claude/blueprint-logs/ 内の open ステータスログ数をカウントし、
# 閾値（デフォルト: 10件）以上で stderr 経由でユーザーに通知する。

set -euo pipefail

LOG_DIR="${HOME}/.claude/blueprint-logs"
THRESHOLD=10

# ログディレクトリが存在しなければ何もしない
if [ ! -d "$LOG_DIR" ]; then
    echo '{"continue": true}'
    exit 0
fi

# 未分析ログ数をカウント（triage.status: open のファイル数）
# glob が展開されない場合に備えて shopt -s nullglob を使用
LOG_FILES=()
shopt -s nullglob
LOG_FILES=("${LOG_DIR}"/bl-*.yaml)
shopt -u nullglob

if [ ${#LOG_FILES[@]} -eq 0 ]; then
    echo '{"continue": true}'
    exit 0
fi

PENDING=$(grep -rl 'status: open' "${LOG_FILES[@]}" 2>/dev/null | wc -l | tr -d ' ')

if [ "$PENDING" -ge "$THRESHOLD" ]; then
    exec 3>&2
    echo "" >&3
    echo "📊 未分析の blueprint ログが ${PENDING} 件あります。/blueprint-improve で分析できます" >&3
fi

echo '{"continue": true}'
