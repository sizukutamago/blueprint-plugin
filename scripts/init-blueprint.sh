#!/usr/bin/env bash
# init-blueprint.sh
# .blueprint/ ディレクトリ構造を初期化する

set -euo pipefail

PROJECT_ROOT="${1:-$(pwd)}"
BLUEPRINT_DIR="${PROJECT_ROOT}/.blueprint"

echo "Initializing .blueprint/ in: ${PROJECT_ROOT}"

mkdir -p \
  "${BLUEPRINT_DIR}/contracts" \
  "${BLUEPRINT_DIR}/concepts" \
  "${BLUEPRINT_DIR}/decisions"

echo ".blueprint/ initialized successfully."
echo ""
echo "Directory structure:"
echo "${BLUEPRINT_DIR}/"
echo "├── contracts/"
echo "├── concepts/"
echo "└── decisions/"
