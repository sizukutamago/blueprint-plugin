#!/usr/bin/env bash
# assert-gate-completed.sh
# Step 7: Code Review Gate の実行済みを確認する
#
# Usage: bash .blueprint/scripts/assert-gate-completed.sh [PROJECT_ROOT]
# Exit:  0 = Gate 実行確認 OK (status: passed)
#        1 = Gate 未実行 / REVISE サイクル中

set -euo pipefail

PROJECT_ROOT="${1:-$(pwd)}"
PIPELINE_STATE="${PROJECT_ROOT}/.blueprint/pipeline-state.yaml"

# ─── pipeline-state.yaml の存在確認 ─────────────────────────────────
if [ ! -f "$PIPELINE_STATE" ]; then
  echo "ERROR: .blueprint/pipeline-state.yaml が見つかりません"
  echo ""
  echo "  Code Review Gate を実行し、pipeline-state.yaml を更新してください:"
  echo "  → SKILL.md Step 7 の Code Review Gate（4 Agent 並列）を実行"
  echo "  → Gate 結果を .blueprint/pipeline-state.yaml に記録"
  echo ""
  echo "  テスト GREEN だけで完了とみなしてはなりません。"
  exit 1
fi

# ─── code_review_gate エントリと status を一度に取得 ──────────────────
GATE_BLOCK=$(grep -A5 "code_review_gate:" "$PIPELINE_STATE" 2>/dev/null || echo "")

if [ -z "$GATE_BLOCK" ]; then
  echo "ERROR: pipeline-state.yaml に code_review_gate エントリがありません"
  echo ""
  echo "  Step 7 の Code Review Gate（4 Agent 並列）を実行してください:"
  echo "    Agent 1: Schema Compliance Checker"
  echo "    Agent 2: Route & Handler Checker"
  echo "    Agent 3: Business Logic Checker"
  echo "    Agent 4: Code Quality Checker"
  echo ""
  echo "  実行後、pipeline-state.yaml を更新してください:"
  echo "    code_review_gate:"
  echo "      status: passed"
  echo "      cycle: 1"
  exit 1
fi

STATUS=$(echo "$GATE_BLOCK" | grep "status:" | head -1 | awk '{print $2}' | tr -d "\"'" || echo "")

case "$STATUS" in
  passed|pass|complete|completed)
    echo "✓ Code Review Gate 実行確認: OK (status: ${STATUS})"
    exit 0
    ;;
  revising|failed)
    CYCLE=$(echo "$GATE_BLOCK" | grep "cycles:" | head -1 | awk '{print $2}' || echo "?")
    echo "ERROR: Code Review Gate が REVISE サイクル中または失敗しています (status: ${STATUS}, cycles: ${CYCLE})"
    echo ""
    echo "  まだ承認フェーズへ進めません。"
    echo "  REVISE サイクルを完了し、status を 'passed' に更新してください。"
    exit 1
    ;;
  pending|skipped|not_run|"")
    echo "ERROR: Code Review Gate が未実行です (status: ${STATUS:-未設定})"
    echo ""
    echo "  テスト GREEN だけで完了とみなしてはなりません。"
    echo "  Step 7 の Code Review Gate（4 Agent 並列）を必ず実行してください。"
    exit 1
    ;;
  *)
    # 不明な status はエラーとして扱う（安全側に倒す）
    echo "ERROR: Code Review Gate の status が不明です (status: ${STATUS})"
    echo ""
    echo "  有効な status: passed | revising | pending | skipped"
    echo "  Step 7 の Code Review Gate を実行し、pipeline-state.yaml を更新してください。"
    exit 1
    ;;
esac
