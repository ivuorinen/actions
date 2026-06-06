#!/bin/sh
set -eu

# Block direct edits to generated per-action validate.py files.
#
# Each <action>/validate.py is produced by _validation/generate.py from the canonical
# _validation/kit.py (check implementations) + _validation/spec.py (input -> check map).
# Hand-editing one would drift from the generator. To change what an action validates,
# edit _validation/spec.py (or kit.py) and run `make update-validators`.

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
*/validate.py)
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"validate.py is auto-generated. Edit _validation/spec.py or _validation/kit.py and run make update-validators instead."}}'
  ;;
esac
