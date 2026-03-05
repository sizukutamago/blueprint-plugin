#!/usr/bin/env bash
# verify-web-app.sh
# Step 6.5: Web App 動作確認スクリプト
#
# Usage: bash .blueprint/scripts/verify-web-app.sh [PROJECT_ROOT]
# Exit:  0 = 全エンドポイント OK / api Contract なし
#        1 = 失敗あり / サーバー起動失敗

set -euo pipefail

PROJECT_ROOT="${1:-$(pwd)}"
MAX_WAIT=30

# ─── 空きポート検出関数 ───────────────────────────────────────────────
# lsof が存在しない環境（CI コンテナ等）では ss → nc にフォールバック
_port_in_use() {
  local p="$1"
  if command -v lsof > /dev/null 2>&1; then
    lsof -i :"$p" > /dev/null 2>&1
  elif command -v ss > /dev/null 2>&1; then
    ss -ltn 2>/dev/null | grep -q ":${p} "
  else
    nc -z localhost "$p" > /dev/null 2>&1
  fi
}

find_free_port() {
  local port="${1:-3000}"
  local max=$((port + 20))
  while [ "$port" -le "$max" ]; do
    if ! _port_in_use "$port"; then
      echo "$port"; return 0
    fi
    port=$((port + 1))
  done
  return 1
}

PORT=$(find_free_port "${PORT:-3000}") || { echo "ERROR: 3000-3020 番ポートが全て使用中"; exit 1; }

RESULTS_DIR="${PROJECT_ROOT}/.blueprint/reviews"
TIMESTAMP=$(date +%Y%m%d-%H%M)
RESULT_FILE="${RESULTS_DIR}/web-verification-${TIMESTAMP}.md"

# ─── 1. config.yaml から framework + package_manager 検出 ────────────
CONFIG="${PROJECT_ROOT}/.blueprint/config.yaml"
if [ ! -f "$CONFIG" ]; then
  echo "ERROR: .blueprint/config.yaml が見つかりません (/spec を先に実行してください)"
  exit 1
fi

FRAMEWORK=$(grep -m1 "framework:" "$CONFIG" 2>/dev/null | awk '{print $2}' | tr -d '"'"'" || echo "unknown")
PKG_MANAGER=$(grep -m1 "package_manager:" "$CONFIG" 2>/dev/null | awk '{print $2}' | tr -d '"'"'" || echo "npm")

echo "=== Web App 動作確認 ==="
echo "Framework : ${FRAMEWORK}"
echo "Pkg mgr   : ${PKG_MANAGER}"
echo "Port      : ${PORT}"
echo ""

# ─── 2. package.json の dev/start/serve スクリプト確認 ───────────────
PKG_JSON="${PROJECT_ROOT}/package.json"
if [ ! -f "$PKG_JSON" ]; then
  echo "WARNING: package.json が見つかりません。スキップ。"
  exit 0
fi

HAS_SCRIPT=$(node -e "
  const p = JSON.parse(require('fs').readFileSync('${PKG_JSON}', 'utf8'));
  const s = p.scripts || {};
  console.log(s.dev || s.start || s.serve ? 'yes' : 'no');
" 2>/dev/null || echo "no")

# ─── 3. スクリプトがなければサーバーファイルを自動生成 ───────────────
if [ "$HAS_SCRIPT" = "no" ]; then
  echo "⚠ dev/start/serve スクリプトが見つかりません。サーバーファイルを自動生成します..."
  echo ""

  SRC_DIR="${PROJECT_ROOT}/src"
  mkdir -p "$SRC_DIR"

  case "$FRAMEWORK" in
    hono)
      printf '%s\n' \
        'import { serve } from "@hono/node-server";' \
        'import { createApp } from "./app.ts";' \
        '' \
        'const port = Number(process.env.PORT ?? 3000);' \
        'const app = createApp();' \
        '' \
        'serve({ fetch: app.fetch, port }, () => {' \
        '  console.log(`Server running on http://localhost:${port}`);' \
        '});' \
        > "${SRC_DIR}/server.ts"
      echo "Generated: src/server.ts (hono)"
      START_CMD="tsx src/server.ts"
      INSTALL_EXTRA="@hono/node-server"
      ;;
    express)
      printf '%s\n' \
        'import app from "./app.ts";' \
        '' \
        'const port = Number(process.env.PORT ?? 3000);' \
        'app.listen(port, () => {' \
        '  console.log(`Server running on http://localhost:${port}`);' \
        '});' \
        > "${SRC_DIR}/server.ts"
      echo "Generated: src/server.ts (express)"
      START_CMD="tsx src/server.ts"
      INSTALL_EXTRA=""
      ;;
    fastify)
      printf '%s\n' \
        'import app from "./app.ts";' \
        '' \
        'const port = Number(process.env.PORT ?? 3000);' \
        'app.listen({ port }, (err) => {' \
        '  if (err) { console.error(err); process.exit(1); }' \
        '  console.log(`Server running on http://localhost:${port}`);' \
        '});' \
        > "${SRC_DIR}/server.ts"
      echo "Generated: src/server.ts (fastify)"
      START_CMD="tsx src/server.ts"
      INSTALL_EXTRA=""
      ;;
    *)
      printf '%s\n' \
        'import http from "node:http";' \
        '' \
        'const port = Number(process.env.PORT ?? 3000);' \
        'const server = http.createServer((_req, res) => {' \
        '  res.writeHead(404);' \
        '  res.end("Not Found");' \
        '});' \
        'server.listen(port, () => {' \
        '  console.log(`Server running on http://localhost:${port}`);' \
        '});' \
        > "${SRC_DIR}/server.ts"
      echo "Generated: src/server.ts (node:http)"
      START_CMD="tsx src/server.ts"
      INSTALL_EXTRA=""
      ;;
  esac

  # tsx をインストール
  cd "$PROJECT_ROOT"
  # tsx がまだインストールされていない場合のみインストール
  if [ ! -x "node_modules/.bin/tsx" ]; then
    echo "Installing tsx..."
    case "$PKG_MANAGER" in
      pnpm) pnpm add -D tsx ${INSTALL_EXTRA:+$INSTALL_EXTRA} ;;
      yarn) yarn add -D tsx ${INSTALL_EXTRA:+$INSTALL_EXTRA} ;;
      bun)  bun add -D tsx ${INSTALL_EXTRA:+$INSTALL_EXTRA} ;;
      *)    npm install -D tsx ${INSTALL_EXTRA:+$INSTALL_EXTRA} ;;
    esac
  else
    echo "tsx already installed, skipping."
    # INSTALL_EXTRA（フレームワークアダプター）は別途確認
    if [ -n "${INSTALL_EXTRA:-}" ] && [ ! -d "node_modules/$(echo "$INSTALL_EXTRA" | awk -F'/' '{print $1}')" ]; then
      echo "Installing ${INSTALL_EXTRA}..."
      case "$PKG_MANAGER" in
        pnpm) pnpm add "$INSTALL_EXTRA" ;;
        yarn) yarn add "$INSTALL_EXTRA" ;;
        bun)  bun add "$INSTALL_EXTRA" ;;
        *)    npm install "$INSTALL_EXTRA" ;;
      esac
    fi
  fi

  # package.json に start/dev を追加
  node -e "
    const fs = require('fs');
    const pkg = JSON.parse(fs.readFileSync('${PKG_JSON}', 'utf8'));
    pkg.scripts = pkg.scripts || {};
    if (!pkg.scripts.start) pkg.scripts.start = '${START_CMD}';
    if (!pkg.scripts.dev) pkg.scripts.dev = 'tsx watch src/server.ts';
    fs.writeFileSync('${PKG_JSON}', JSON.stringify(pkg, null, 2) + '\n');
    console.log('package.json: start/dev scripts added');
  "
  echo ""
fi

# ─── 4. 起動コマンド決定 ─────────────────────────────────────────────
RUN_CMD=$(node -e "
  const p = JSON.parse(require('fs').readFileSync('${PKG_JSON}', 'utf8'));
  const s = p.scripts || {};
  if (s.dev) process.stdout.write('dev');
  else if (s.start) process.stdout.write('start');
  else if (s.serve) process.stdout.write('serve');
  else process.stdout.write('');
" 2>/dev/null || echo "")

if [ -z "$RUN_CMD" ]; then
  echo "ERROR: 起動スクリプトが見つかりません"
  exit 1
fi

# ─── 5. サーバー起動 ──────────────────────────────────────────────────
cd "$PROJECT_ROOT"
echo "Starting: ${PKG_MANAGER} run ${RUN_CMD}"
PORT="$PORT" "${PKG_MANAGER}" run "$RUN_CMD" > /tmp/blueprint-server-$$.log 2>&1 &
SERVER_PID=$!

# 強制終了時でもサーバーを確実に停止する
# shellcheck disable=SC2064
trap "kill $SERVER_PID 2>/dev/null || true; rm -f /tmp/blueprint-server-$$.log" EXIT

# 起動待機（最大 MAX_WAIT 秒）- プロセス死亡も早期検出
echo -n "Waiting for server on port ${PORT}"
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
  # サーバープロセスが落ちた場合は即座に失敗
  if ! kill -0 $SERVER_PID 2>/dev/null; then
    echo " CRASHED"
    echo ""
    echo "Server log:"
    cat /tmp/blueprint-server-$$.log 2>/dev/null || true
    exit 1
  fi
  if curl -s "http://localhost:${PORT}/" > /dev/null 2>&1; then
    echo " ✓"
    break
  fi
  sleep 3
  WAITED=$((WAITED + 3))
  echo -n "."
done

if [ $WAITED -ge $MAX_WAIT ]; then
  echo " TIMEOUT"
  echo ""
  echo "Server log:"
  cat /tmp/blueprint-server-$$.log 2>/dev/null || true
  exit 1
fi
echo ""

# ─── 6. api Contract のスキャン ──────────────────────────────────────
CONTRACTS_DIR="${PROJECT_ROOT}/.blueprint/contracts"
FAIL_COUNT=0
PASS_COUNT=0
RESULT_ROWS=""

if [ ! -d "$CONTRACTS_DIR" ]; then
  echo "WARNING: .blueprint/contracts/ が見つかりません"
  exit 0  # trap が SERVER_PID のクリーンアップを行う
fi

echo "--- API Smoke Tests ---"

# api type の contract ファイルを検索
while IFS= read -r -d '' contract_file; do
  type_val=$(grep -m1 "^type:" "$contract_file" 2>/dev/null | awk '{print $2}' | tr -d '"'"'" || echo "")
  [ "$type_val" = "api" ] || continue

  method=$(grep -m1 "method:" "$contract_file" 2>/dev/null | awk '{print $2}' | tr -d '"'"'" | tr '[:lower:]' '[:upper:]' || echo "GET")
  path=$(grep -m1 "path:" "$contract_file" 2>/dev/null | awk '{print $2}' | tr -d '"'"'" || echo "/")

  STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -X "$method" \
    "http://localhost:${PORT}${path}" \
    -H "Content-Type: application/json" \
    --max-time 10 \
    2>/dev/null || echo "000")

  FIRST_DIGIT="${STATUS:0:1}"
  if [ "$FIRST_DIGIT" = "5" ] || [ "$STATUS" = "000" ]; then
    RESULT="✗ FAIL"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  else
    RESULT="✓ PASS"
    PASS_COUNT=$((PASS_COUNT + 1))
  fi

  printf "  %-6s %-30s → %s %s\n" "$method" "$path" "$STATUS" "$RESULT"
  RESULT_ROWS="${RESULT_ROWS}| ${method} ${path} | ${STATUS} | ${RESULT} |
"
done < <(find "$CONTRACTS_DIR" -name "*.contract.yaml" -print0 2>/dev/null)

echo ""

# ─── 7. サーバー停止 ──────────────────────────────────────────────────
# trap が EXIT 時にクリーンアップするが、ここで明示的に停止もする
kill $SERVER_PID 2>/dev/null || true
wait $SERVER_PID 2>/dev/null || true
trap - EXIT  # 二重 kill を防ぐため trap を解除
rm -f /tmp/blueprint-server-$$.log
echo "Server stopped."
echo ""

# ─── 8. 結果ファイル出力 ──────────────────────────────────────────────
mkdir -p "$RESULTS_DIR"
TOTAL=$((PASS_COUNT + FAIL_COUNT))

if [ $TOTAL -eq 0 ]; then
  echo "api Contract が見つかりません。スキップ（正常終了）"
  cat > "$RESULT_FILE" << RESULTEOF
# Web App 動作確認結果

**実施日時**: $(date)
**結果**: api Contract なし（スキップ）
RESULTEOF
  echo "Result: ${RESULT_FILE}"
  exit 0
fi

{
  echo "# Web App 動作確認結果"
  echo ""
  echo "**実施日時**: $(date)"
  echo "**結果**: ${PASS_COUNT}/${TOTAL} PASS"
  echo ""
  echo "| エンドポイント | ステータス | 結果 |"
  echo "|-------------|----------|------|"
  printf "%s" "$RESULT_ROWS"
} > "$RESULT_FILE"

echo "=== Summary ==="
echo "Result    : ${PASS_COUNT}/${TOTAL} PASS"
echo "Saved to  : ${RESULT_FILE}"

if [ $FAIL_COUNT -gt 0 ]; then
  echo ""
  echo "ERROR: ${FAIL_COUNT} エンドポイントが失敗しました"
  exit 1
fi

echo "✓ All endpoints OK"
exit 0
