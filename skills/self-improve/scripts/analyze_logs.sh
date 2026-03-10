#!/bin/bash
# analyze_logs.sh - blueprint ログの統計集計 + パターン検出
#
# 使用法:
#   analyze_logs.sh              # 未分析ログの統計サマリー出力（YAML）
#   analyze_logs.sh --details    # パターン別詳細出力
#   analyze_logs.sh --count      # 未分析ログ数のみ出力
#
# 出力: YAML 形式の統計レポート（stdout）
# 入力: ~/.claude/blueprint-logs/bl-*.yaml（triage.status: open のもの）

set -euo pipefail

LOG_DIR="${HOME}/.claude/blueprint-logs"
MODE="${1:-}"

# --- ログディレクトリチェック ---
if [ ! -d "$LOG_DIR" ]; then
    echo "error: ログディレクトリが存在しません: ${LOG_DIR}" >&2
    exit 1
fi

# --- 未分析ログの収集 ---
shopt -s nullglob
ALL_LOG_FILES=("${LOG_DIR}"/bl-*.yaml)
shopt -u nullglob

OPEN_LOGS=()
if [ ${#ALL_LOG_FILES[@]} -gt 0 ]; then
    while IFS= read -r file; do
        OPEN_LOGS+=("$file")
    done < <(grep -rl 'status: open' "${ALL_LOG_FILES[@]}" 2>/dev/null || true)
fi

LOG_COUNT=${#OPEN_LOGS[@]}

if [ "$LOG_COUNT" -eq 0 ]; then
    echo "info: 未分析ログはありません" >&2
    echo "log_count: 0"
    exit 0
fi

# --- カウントモード ---
if [ "$MODE" = "--count" ]; then
    echo "$LOG_COUNT"
    exit 0
fi

# --- 基本統計の集計 ---

# ステージ別集計
STAGE_SPEC=0
STAGE_TEST=0
STAGE_IMPL=0
STAGE_DOCS=0

# Gate 結果集計
TOTAL_P0=0
TOTAL_P1=0
TOTAL_P2=0
GATE_PASS=0
GATE_REVISE=0

# エラー集計
TOTAL_ERRORS=0

# ユーザー修正集計
TOTAL_CORRECTIONS=0

# パイプライン状態集計
COMPLETED=0
PARTIAL=0
FAILED=0

# Gate findings の category 集計（一時ファイル）
CATEGORY_TMP=$(mktemp)
ERROR_TYPE_TMP=$(mktemp)
CORRECTION_STAGE_TMP=$(mktemp)
trap 'rm -f "$CATEGORY_TMP" "$ERROR_TYPE_TMP" "$CORRECTION_STAGE_TMP"' EXIT

for log_file in "${OPEN_LOGS[@]}"; do
    # ステージ検出（stages_executed 行のみ対象。ファイル全体の grep だと誤検出する）
    STAGES_LINE=$(grep 'stages_executed:' "$log_file" 2>/dev/null | head -1 || echo "")
    if echo "$STAGES_LINE" | grep -q 'spec'; then
        STAGE_SPEC=$((STAGE_SPEC + 1))
    fi
    if echo "$STAGES_LINE" | grep -q 'test-from-contract'; then
        STAGE_TEST=$((STAGE_TEST + 1))
    fi
    if echo "$STAGES_LINE" | grep -q 'implement'; then
        STAGE_IMPL=$((STAGE_IMPL + 1))
    fi
    if echo "$STAGES_LINE" | grep -q 'generate-docs'; then
        STAGE_DOCS=$((STAGE_DOCS + 1))
    fi

    # final_status 集計
    STATUS=$(grep 'final_status:' "$log_file" 2>/dev/null | head -1 | sed 's/.*: *//' | tr -d '"' || echo "unknown")
    case "$STATUS" in
        completed) COMPLETED=$((COMPLETED + 1)) ;;
        partial) PARTIAL=$((PARTIAL + 1)) ;;
        failed) FAILED=$((FAILED + 1)) ;;
    esac

    # P0/P1/P2 集計（counts セクション内の値を合算）（counts セクション内 "p0: N" → コロン以降の数値のみ）
    P0_VAL=$(awk '/[[:space:]]p0:/{split($0,a,": "); sum+=a[2]+0} END{print sum+0}' "$log_file" 2>/dev/null || echo "0")
    P1_VAL=$(awk '/[[:space:]]p1:/{split($0,a,": "); sum+=a[2]+0} END{print sum+0}' "$log_file" 2>/dev/null || echo "0")
    P2_VAL=$(awk '/[[:space:]]p2:/{split($0,a,": "); sum+=a[2]+0} END{print sum+0}' "$log_file" 2>/dev/null || echo "0")
    TOTAL_P0=$((TOTAL_P0 + P0_VAL))
    TOTAL_P1=$((TOTAL_P1 + P1_VAL))
    TOTAL_P2=$((TOTAL_P2 + P2_VAL))

    # Gate pass/revise 集計
    PASS_COUNT=$(awk '/status: passed/{c++} END{print c+0}' "$log_file" 2>/dev/null || echo "0")
    REVISE_COUNT=$(awk '/status: revise/{c++} END{print c+0}' "$log_file" 2>/dev/null || echo "0")
    GATE_PASS=$((GATE_PASS + PASS_COUNT))
    GATE_REVISE=$((GATE_REVISE + REVISE_COUNT))

    # category 集計
    grep 'category:' "$log_file" 2>/dev/null | sed 's/.*category: *//' | tr -d '"' >> "$CATEGORY_TMP" || true

    # エラー数
    ERR_COUNT=$(awk '/type: "tool_error"/{c++} END{print c+0}' "$log_file" 2>/dev/null || echo "0")
    TOTAL_ERRORS=$((TOTAL_ERRORS + ERR_COUNT))
    grep 'phase:' "$log_file" 2>/dev/null | sed 's/.*phase: *//' | tr -d '"' >> "$ERROR_TYPE_TMP" || true

    # ユーザー修正数（user_corrections の count のみ）
    CORR_COUNT=$(awk '/^user_corrections:/,/^[a-z#]/{if(/count:/){split($0,a,": "); print a[2]+0; exit}}' "$log_file" 2>/dev/null || echo "0")
    [ -z "$CORR_COUNT" ] && CORR_COUNT=0
    TOTAL_CORRECTIONS=$((TOTAL_CORRECTIONS + CORR_COUNT))
    grep 'stage:' "$log_file" 2>/dev/null | sed 's/.*stage: *//' | tr -d '"' >> "$CORRECTION_STAGE_TMP" || true
done

# --- ログ ID 範囲 ---
FIRST_LOG=$(basename "${OPEN_LOGS[0]}" .yaml)
LAST_LOG=$(basename "${OPEN_LOGS[$((LOG_COUNT - 1))]}" .yaml)

# --- YAML 出力 ---
echo "# Blueprint ログ分析レポート"
echo "# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""
echo "summary:"
echo "  log_count: ${LOG_COUNT}"
echo "  log_range:"
echo "    from: \"${FIRST_LOG}\""
echo "    to: \"${LAST_LOG}\""
echo ""
echo "  pipeline_results:"
echo "    completed: ${COMPLETED}"
echo "    partial: ${PARTIAL}"
echo "    failed: ${FAILED}"
echo ""
echo "  stages:"
echo "    spec: ${STAGE_SPEC}"
echo "    test_from_contract: ${STAGE_TEST}"
echo "    implement: ${STAGE_IMPL}"
echo "    generate_docs: ${STAGE_DOCS}"
echo ""
echo "  gate_findings:"
echo "    total_p0: ${TOTAL_P0}"
echo "    total_p1: ${TOTAL_P1}"
echo "    total_p2: ${TOTAL_P2}"
echo "    gates_passed: ${GATE_PASS}"
echo "    gates_revised: ${GATE_REVISE}"
echo ""
echo "  errors:"
echo "    total: ${TOTAL_ERRORS}"
echo ""
echo "  user_corrections:"
echo "    total: ${TOTAL_CORRECTIONS}"

# --- 詳細モード ---
if [ "$MODE" = "--details" ]; then
    echo ""
    echo "# === パターン詳細 ==="
    echo ""

    # category 別集計
    echo "category_distribution:"
    if [ -s "$CATEGORY_TMP" ]; then
        sort "$CATEGORY_TMP" | uniq -c | sort -rn | while read count category; do
            echo "  - category: \"${category}\""
            echo "    count: ${count}"
        done
    else
        echo "  []"
    fi

    echo ""

    # エラー phase 別集計
    echo "error_phase_distribution:"
    if [ -s "$ERROR_TYPE_TMP" ]; then
        sort "$ERROR_TYPE_TMP" | uniq -c | sort -rn | while read count phase; do
            echo "  - phase: \"${phase}\""
            echo "    count: ${count}"
        done
    else
        echo "  []"
    fi

    echo ""

    # ユーザー修正 stage 別集計
    echo "correction_stage_distribution:"
    if [ -s "$CORRECTION_STAGE_TMP" ]; then
        sort "$CORRECTION_STAGE_TMP" | uniq -c | sort -rn | while read count stage; do
            echo "  - stage: \"${stage}\""
            echo "    count: ${count}"
        done
    else
        echo "  []"
    fi
fi
