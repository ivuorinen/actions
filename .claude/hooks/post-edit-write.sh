#!/bin/sh
set -eu

# Read JSON input from stdin to get the file path
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required but not found" >&2
  exit 1
fi

INPUT=$(cat)
FILE_PATH=$(printf '%s' "$INPUT" | LC_ALL=C tr -d '\000-\010\013\014\016-\037' | jq -r '.tool_input.file_path // .tool_input.filePath // empty' 2>/dev/null || true)

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

case "$FILE_PATH" in
*/rules.yml)
  # rules.yml should not be reached here (blocked by PreToolUse),
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
*.yml | *.yaml | *.json)
  npx prettier --write "$FILE_PATH" 2>/dev/null || true
  ;;
*.md)
  npx prettier --write "$FILE_PATH" 2>/dev/null || true
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
