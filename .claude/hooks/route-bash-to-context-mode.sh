#!/bin/sh
# Route all Bash through context-mode: permit only `git commit` and `git push`.
#
# Every other command — reads (ls, cat, grep, git status/diff/log, make, gh
# queries) AND mutations (git add, mkdir, rm, mv, make targets, gh writes) — must
# go through the context-mode MCP tools (ctx_execute / ctx_batch_execute), which
# persist filesystem and git-index changes to the real repo; file content goes
# through Edit/Write. This keeps terminal output out of the context window.
# See .claude/rules/context-mode-always.md.
set -eu

# Fail open if jq is unavailable (matches the other PreToolUse hooks).
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

INPUT=$(cat)
CLEAN_INPUT=$(printf '%s' "$INPUT" | LC_ALL=C tr -d '\000-\010\013\014\016-\037')
CMD=$(printf '%s' "$CLEAN_INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || true)

# Nothing to inspect -> allow.
if [ -z "$CMD" ]; then
  exit 0
fi

# Strip leading whitespace, then permit only `git commit` / `git push` (with args).
TRIMMED=$(printf '%s' "$CMD" | sed -E 's/^[[:space:]]+//')
case "$TRIMMED" in
"git commit" | "git commit "* | "git push" | "git push "*) exit 0 ;;
esac

REASON="Bash is restricted to 'git commit' and 'git push' in this repo. Route everything else through context-mode: reads AND mutations (git add, mkdir, rm, mv, make, gh, ...) via ctx_execute or ctx_batch_execute (these persist filesystem and git-index changes to the real repo), and file content via Edit/Write. This keeps terminal output out of the context window. See .claude/rules/context-mode-always.md."
ENCODED=$(printf '%s' "$REASON" | jq -Rs .)
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":%s}}\n' "$ENCODED"
