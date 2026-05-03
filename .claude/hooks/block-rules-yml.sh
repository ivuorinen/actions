#!/bin/sh
set -eu

# Read JSON input from stdin to get the file path
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required but not found" >&2
  exit 1
fi

INPUT=$(cat)
CLEAN_INPUT=$(printf '%s' "$INPUT" | LC_ALL=C tr -d '\000-\010\013\014\016-\037')
FILE_PATH=$(printf '%s' "$CLEAN_INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty' 2>/dev/null || true)

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

case "$FILE_PATH" in
*/rules.yml)
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"rules.yml files are auto-generated. Run make update-validators instead."}}'
  ;;
esac
