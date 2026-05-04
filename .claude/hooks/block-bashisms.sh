#!/bin/sh
set -eu

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

INPUT=$(cat)
FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Only check shell scripts and action.yml
case "$FILE_PATH" in
*.sh | *.bash | */action.yml | */action.yaml) ;;
*) exit 0 ;;
esac

# _tests/framework/ is intentionally bash (uses export -f, local, etc.)
case "$FILE_PATH" in
*/_tests/framework/*) exit 0 ;;
esac

NEW_CONTENT=$(printf '%s' "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // empty')

if [ -z "$NEW_CONTENT" ]; then
  exit 0
fi

# Strip comment lines before checking — avoids false positives on prose
# For action.yml, the new_string from Edit is already scoped to the snippet
CHECKABLE=$(printf '%s\n' "$NEW_CONTENT" | grep -v '^\s*#' || true)

if [ -z "$CHECKABLE" ]; then
  exit 0
fi

# Collect all violations into REASON
REASON=""

# --- Conditionals & operators ---
if printf '%s\n' "$CHECKABLE" | grep -qE '\[{2}([^:]|$)'; then
  REASON="${REASON}[[ ]] is not POSIX. Use [ ] or case/test instead. "
fi

if printf '%s\n' "$CHECKABLE" | grep -qE '=~'; then
  REASON="${REASON}=~ regex operator is bash-only. Use case or expr for matching. "
fi

# --- Variable/function declarations ---
if printf '%s\n' "$CHECKABLE" | grep -qE '(^|[[:space:]])(declare|typeset)[[:space:]]'; then
  REASON="${REASON}declare/typeset is not POSIX. Use plain assignment. "
fi

if printf '%s\n' "$CHECKABLE" | grep -qE '(^|[[:space:]])function[[:space:]]+[a-zA-Z_]'; then
  REASON="${REASON}function keyword is not POSIX. Use name() { ... } syntax. "
fi

# --- local keyword ---
if printf '%s\n' "$CHECKABLE" | grep -qE '(^|;) *local '; then
  REASON="${REASON}local builtin is not POSIX. Use plain assignment at function-level scope. "
fi

# --- echo flags ---
if printf '%s\n' "$CHECKABLE" | grep -qE '(^|[[:space:]])echo[[:space:]]+-[en]'; then
  REASON="${REASON}echo -e/-n is not portable. Use printf instead. "
fi

# --- read flags ---
if printf '%s\n' "$CHECKABLE" | grep -qE '(^|[[:space:]])read[[:space:]]+-[pa]'; then
  REASON="${REASON}read -p/-a are bash-only. Use printf+read or positional parsing. "
fi

# --- Bash-only variables ---
# shellcheck disable=SC2016
if printf '%s\n' "$CHECKABLE" | grep -qE '\$(RANDOM|BASH_VERSION|BASHPID|BASH_SOURCE)'; then
  REASON="${REASON}\$RANDOM/\$BASH_VERSION/\$BASHPID/\$BASH_SOURCE are bash-only. "
fi

# --- Herestring ---
if printf '%s\n' "$CHECKABLE" | grep -qE '<<<'; then
  REASON="${REASON}<<< herestring is bash-only. Use printf | or here-documents. "
fi

# --- Bash-only redirects ---
if printf '%s\n' "$CHECKABLE" | grep -qE '&>'; then
  REASON="${REASON}&> redirect is bash-only. Use >file 2>&1 instead. "
fi

# --- pipefail ---
if printf '%s\n' "$CHECKABLE" | grep -qE 'set[[:space:]].*pipefail'; then
  REASON="${REASON}pipefail is not POSIX. Remove or restructure to avoid pipes in set -e contexts. "
fi

# --- source keyword ---
if printf '%s\n' "$CHECKABLE" | grep -qE '(^|[[:space:]])source[[:space:]]+'; then
  REASON="${REASON}source is bash-only. Use . (dot) to include files. "
fi

# --- Array syntax ---
if printf '%s\n' "$CHECKABLE" | grep -qE '[a-zA-Z_]+[a-zA-Z0-9_]*=\('; then
  REASON="${REASON}Array assignment var=() is bash-only. Use space-delimited strings. "
fi

if printf '%s\n' "$CHECKABLE" | grep -qE '\$\{[a-zA-Z_][a-zA-Z0-9_]*\['; then
  REASON="${REASON}Array subscript \${arr[...]} is bash-only. Use positional params or cut/awk. "
fi

if [ -n "$REASON" ]; then
  REASON=$(printf '%s' "$REASON" | sed 's/"/\\"/g')
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"POSIX violation(s): %s All scripts must be POSIX sh (set -eu), not bash."}}\n' "$REASON"
fi
