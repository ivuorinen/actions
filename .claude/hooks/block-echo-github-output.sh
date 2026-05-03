#!/bin/sh
set -eu

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

INPUT=$(cat)
CLEAN_INPUT=$(printf '%s' "$INPUT" | LC_ALL=C tr -d '\000-\010\013\014\016-\037')
FILE_PATH=$(printf '%s' "$CLEAN_INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty' 2>/dev/null || true)

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Only check action.yml files
case "$FILE_PATH" in
*/action.yml | */.github/workflows/*.yml | */.github/workflows/*.yaml) ;;
*) exit 0 ;;
esac

# Check new_string (Edit) or content (Write) for echo→GITHUB_OUTPUT pattern
NEW_CONTENT=$(printf '%s' "$CLEAN_INPUT" | jq -r '.tool_input.new_string // .tool_input.content // empty' 2>/dev/null || true)

if [ -z "$NEW_CONTENT" ]; then
  exit 0
fi

if printf '%s' "$NEW_CONTENT" | grep -q 'echo.*>>.*GITHUB_OUTPUT'; then
  # shellcheck disable=SC2016
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Use printf with format-string separation, not echo, for GITHUB_OUTPUT. Example: printf '\''key=%s\n'\'' \"$value\" >> \"$GITHUB_OUTPUT\""}}'
fi
