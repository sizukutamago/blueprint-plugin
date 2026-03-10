#!/bin/bash
# collect_blueprint_log.sh - SessionEnd hook: blueprint 使用セッションのログを自動収集
#
# データソース優先順位:
#   1. pipeline-state.yaml（主）: Gate findings, stage status, cycles
#   2. transcript（補）: user_corrections, tool errors のみ
#
# 収集条件:
#   - .blueprint/pipeline-state.yaml が存在する
#   - OR transcript に blueprint スキル使用痕跡がある
#
# 出力: ~/.claude/blueprint-logs/bl-{YYYYMMDD}-{SEQ}.yaml

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${HOME}/.claude/blueprint-logs"
THRESHOLD=10

# --- stdin から hook データを読み取り ---
INPUT=$(cat)

if [ -z "$INPUT" ]; then
    echo '{"continue": true}'
    exit 0
fi

# --- フィールド抽出（jq 優先、フォールバック grep） ---
if command -v jq &>/dev/null; then
    SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
    TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')
    CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
else
    SESSION_ID=$(echo "$INPUT" | grep -o '"session_id":"[^"]*"' | cut -d'"' -f4)
    TRANSCRIPT_PATH=$(echo "$INPUT" | grep -o '"transcript_path":"[^"]*"' | cut -d'"' -f4)
    CWD=$(echo "$INPUT" | grep -o '"cwd":"[^"]*"' | cut -d'"' -f4)
fi

# cwd フォールバック
if [ -z "$CWD" ]; then
    CWD="$(pwd)"
fi

# --- blueprint 使用判定 ---
PIPELINE_STATE="${CWD}/.blueprint/pipeline-state.yaml"
PIPELINE_STATE_PRESENT=false
BLUEPRINT_USED=false

# 判定1: pipeline-state.yaml の存在チェック
if [ -f "$PIPELINE_STATE" ]; then
    PIPELINE_STATE_PRESENT=true
    BLUEPRINT_USED=true
fi

# 判定2: transcript から blueprint スキル使用痕跡を検出
if [ "$BLUEPRINT_USED" = false ] && [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
    if grep -qE '"skill"[[:space:]]*:[[:space:]]*"(blueprint-plugin:)?(spec|test-from-contract|implement|generate-docs|orchestrator|blueprint)"' "$TRANSCRIPT_PATH" 2>/dev/null; then
        BLUEPRINT_USED=true
    fi
fi

# blueprint 未使用なら収集しない
if [ "$BLUEPRINT_USED" = false ]; then
    echo '{"continue": true}'
    exit 0
fi

# --- ログディレクトリ作成 ---
mkdir -p "$LOG_DIR"

# --- ID 生成 ---
TODAY=$(date +%Y%m%d)
SEQ=1
while [ -f "${LOG_DIR}/bl-${TODAY}-$(printf '%03d' $SEQ).yaml" ]; do
    SEQ=$((SEQ + 1))
done
LOG_ID="bl-${TODAY}-$(printf '%03d' $SEQ)"
LOG_FILE="${LOG_DIR}/${LOG_ID}.yaml"

# --- pipeline-state.yaml からデータ抽出（主ソース） ---
GATE_RESULTS=""
STAGES_EXECUTED=""
FINAL_STATUS="unknown"

if [ "$PIPELINE_STATE_PRESENT" = true ]; then
    # stages_executed の抽出
    if command -v yq &>/dev/null; then
        FINAL_STATUS=$(yq -r '.final_status // "unknown"' "$PIPELINE_STATE" 2>/dev/null || echo "unknown")
        # yq で gate_results を簡易抽出
        GATE_RESULTS=$(yq -r '
            .stages | to_entries[] | select(.value.gate_result != null) |
            "  - gate: " + .key + "\n    status: " + (.value.gate_result.status // "unknown") +
            "\n    cycles: " + ((.value.gate_result.cycles // 1) | tostring) +
            "\n    counts:" +
            "\n      p0: " + ((.value.gate_result.p0_count // 0) | tostring) +
            "\n      p1: " + ((.value.gate_result.p1_count // 0) | tostring) +
            "\n      p2: " + ((.value.gate_result.p2_count // 0) | tostring)
        ' "$PIPELINE_STATE" 2>/dev/null || echo "")
    else
        # yq がない場合は grep で簡易抽出
        FINAL_STATUS=$(grep -m1 'final_status:' "$PIPELINE_STATE" 2>/dev/null | sed 's/.*: *//' | tr -d '"' || echo "unknown")
    fi

    # 実行されたステージを検出
    STAGES_EXECUTED=""
    for stage in spec test_from_contract implement generate_docs; do
        if grep -q "stage_.*${stage}:" "$PIPELINE_STATE" 2>/dev/null; then
            stage_clean=$(echo "$stage" | tr '_' '-')
            if [ -n "$STAGES_EXECUTED" ]; then
                STAGES_EXECUTED="${STAGES_EXECUTED}, ${stage_clean}"
            else
                STAGES_EXECUTED="${stage_clean}"
            fi
        fi
    done
fi

# --- transcript から補助データ抽出（Python スクリプト） ---
TRANSCRIPT_DATA=""
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ] && [ -f "${SCRIPT_DIR}/extract_transcript_data.py" ]; then
    TRANSCRIPT_DATA=$(python3 "${SCRIPT_DIR}/extract_transcript_data.py" "$TRANSCRIPT_PATH" 2>/dev/null || echo "")
fi

# --- プロジェクト名の取得 ---
PROJECT_NAME=$(basename "$CWD")
if [ -d "${CWD}/.git" ]; then
    REMOTE_URL=$(git -C "$CWD" remote get-url origin 2>/dev/null || echo "")
    if [ -n "$REMOTE_URL" ]; then
        PROJECT_NAME=$(echo "$REMOTE_URL" | sed 's|.*/||' | sed 's|\.git$||')
    fi
fi

# --- fingerprint 生成 ---
if [ -n "$SESSION_ID" ] && [ "$PIPELINE_STATE_PRESENT" = true ]; then
    FINGERPRINT=$(echo -n "${SESSION_ID}:$(md5sum "$PIPELINE_STATE" 2>/dev/null | cut -d' ' -f1 || echo 'no-hash')" | md5sum 2>/dev/null | cut -d' ' -f1 || echo "${SESSION_ID}")
elif [ -n "$SESSION_ID" ]; then
    FINGERPRINT="${SESSION_ID}"
else
    FINGERPRINT="$(date +%s)-$$"
fi

# --- TTL 計算（90日後） ---
if date -v+90d &>/dev/null 2>&1; then
    EXPIRES_AT=$(date -v+90d -u +%Y-%m-%dT%H:%M:%SZ)
else
    EXPIRES_AT=$(date -d "+90 days" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "")
fi

# --- transcript 補助データの解析 ---
ERRORS_SECTION=""
USER_CORRECTIONS_SECTION=""
STATS_SECTION=""

if [ -n "$TRANSCRIPT_DATA" ]; then
    # Python スクリプトの YAML 出力をそのまま取り込み
    ERRORS_SECTION=$(echo "$TRANSCRIPT_DATA" | sed -n '/^errors:/,/^[a-z]/{ /^errors:/d; /^[a-z]/d; p; }')
    USER_CORRECTIONS_SECTION=$(echo "$TRANSCRIPT_DATA" | sed -n '/^user_corrections:/,/^[a-z]/{ /^user_corrections:/d; /^[a-z]/d; p; }')
    STATS_SECTION=$(echo "$TRANSCRIPT_DATA" | sed -n '/^stats:/,/^[a-z]/{ /^stats:/d; /^[a-z]/d; p; }')
fi

# --- YAML ログファイル書き出し ---
cat > "$LOG_FILE" << YAML_EOF
# Blueprint Self-Improve Log
# Auto-generated by collect_blueprint_log.sh

# === 識別 ===
id: "${LOG_ID}"
created_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
session_id: "${SESSION_ID}"
project_root: "${CWD}"
project_name: "${PROJECT_NAME}"

# === パイプライン情報 ===
pipeline:
  stages_executed: [${STAGES_EXECUTED}]
  final_status: "${FINAL_STATUS}"
  pipeline_state_present: ${PIPELINE_STATE_PRESENT}

# === Gate findings（pipeline-state.yaml から抽出） ===
gate_results:
${GATE_RESULTS:-"  []"}

# === エラーパターン（transcript 補助抽出） ===
errors:
${ERRORS_SECTION:-"  []"}

# === ユーザー修正（transcript 補助抽出） ===
user_corrections:
${USER_CORRECTIONS_SECTION:-"  count: 0
  items: []"}

# === セッション統計（transcript 補助抽出） ===
stats:
${STATS_SECTION:-"  message_count: 0
  tool_uses: 0
  code_changes: 0"}

# === 重複防止 ===
fingerprint: "${FINGERPRINT}"
analysis_range: ""
pr_url: ""
log_schema_version: "1.0"

# === トリアージ ===
triage:
  status: open
  analyzed_at: ""

# === プライバシー ===
privacy:
  redacted: false
  expires_at: "${EXPIRES_AT}"
  opt_out: false
YAML_EOF

# --- 閾値通知（SessionEnd 時） ---
shopt -s nullglob
NOTIFY_FILES=("${LOG_DIR}"/bl-*.yaml)
shopt -u nullglob
PENDING=0
if [ ${#NOTIFY_FILES[@]} -gt 0 ]; then
    PENDING=$(grep -rl 'status: open' "${NOTIFY_FILES[@]}" 2>/dev/null | wc -l | tr -d ' ')
fi
if [ "$PENDING" -ge "$THRESHOLD" ]; then
    exec 3>&2
    echo "" >&3
    echo "📊 未分析の blueprint ログが ${PENDING} 件あります。/blueprint-improve で分析できます" >&3
fi

echo '{"continue": true}'
