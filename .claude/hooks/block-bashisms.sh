#!/bin/sh
set -eu

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Only check shell scripts and action.yml
case "$FILE_PATH" in
*.sh | */action.yml) ;;
*) exit 0 ;;
esac

NEW_CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // empty')

if [ -z "$NEW_CONTENT" ]; then
  exit 0
fi

# Check for common bash-isms (but not inside comments or strings carefully)
# Focus on clear violations
REASON=""

if echo "$NEW_CONTENT" | grep -qE '\[\[.*\]\]'; then
  REASON="Use [ ] instead of [[ ]] for POSIX compliance."
fi

if echo "$NEW_CONTENT" | grep -qE 'declare |typeset |local '; then
  REASON="${REASON:+$REASON }Avoid declare/typeset/local — not POSIX. Use plain variable assignment."
fi

if echo "$NEW_CONTENT" | grep -qE 'function [a-zA-Z_]+[[:space:]]*\{'; then
  REASON="${REASON:+$REASON }Use func_name() { instead of function keyword — not POSIX."
fi

if [ -n "$REASON" ]; then
  # Escape for JSON
  REASON=$(printf '%s' "$REASON" | sed 's/"/\\"/g')
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"POSIX violation: $REASON All scripts must be POSIX sh (set -eu), not bash.\"}}"
fi
