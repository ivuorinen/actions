#!/bin/sh
set -eu

# shellcheck source=SCRIPTDIR/lib.sh
. "$(dirname -- "$0")/lib.sh"

read_input
FILE_PATH=$(input_field '.tool_input.file_path // .tool_input.filePath')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

case "$FILE_PATH" in
*/validate.py)
  # Generated validators should not be reached here (blocked by PreToolUse),
  # but skip formatting just in case
  exit 0
  ;;
*.py)
  ruff format --quiet "$FILE_PATH" 2>/dev/null || true
  ruff check --fix --quiet "$FILE_PATH" 2>/dev/null || true
  ;;
*.sh)
  shfmt -w "$FILE_PATH" 2>/dev/null || true
  shellcheck "$FILE_PATH" 2>&1 || true
  ;;
# --no-install: the prettier package-lock.json pins (make install-tools), never a version npx
# would fetch for itself.
*.yml | *.yaml | *.json)
  npx --no-install prettier --write "$FILE_PATH" 2>/dev/null || true
  ;;
*.md)
  npx --no-install prettier --write "$FILE_PATH" 2>/dev/null || true
  ;;
esac

# Run actionlint and action-validator on action.yml files
case "$FILE_PATH" in
*/action.yml)
  if command -v actionlint >/dev/null 2>&1; then
    actionlint "$FILE_PATH" 2>&1 || true
  fi
  if command -v action-validator >/dev/null 2>&1; then
    action-validator "$FILE_PATH" 2>&1 || true
  fi
  ;;
esac
