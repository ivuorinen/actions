# shellcheck shell=sh
# Shared by the hooks in this directory, which source it first.
# It is not a hook itself: .claude/settings.json registers each hook by name.

# The hooks read their input and build their decisions with jq, so without it they exit 2
# with the reason on stderr. For a PreToolUse hook that blocks the tool call; a PostToolUse
# hook runs after the tool, so Claude Code only shows the reason.
if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required by the hooks in .claude/hooks; install jq to work in this repository" >&2
  exit 2
fi

# read_input: read the hook's JSON from stdin into INPUT as sent, so a check reads the
# bytes the tool call carries. A shell variable cannot hold NUL, so each NUL becomes 0x01,
# which jq rejects like any raw control byte: input with either one is not JSON.
read_input() {
  INPUT=$(LC_ALL=C tr '\000' '\001')
}

# read_tool_call: read_input for a PreToolUse hook, which denies a call whose input is not
# JSON, since it cannot check fields it cannot read.
read_tool_call() {
  read_input
  if ! printf '%s' "$INPUT" | jq -e . >/dev/null 2>&1; then
    deny "The hook input is not JSON, so the hook cannot check this tool call."
    exit 0
  fi
}

# input_field FILTER: print the value FILTER selects from INPUT, or nothing when it is
# absent or the input is not JSON.
input_field() {
  printf '%s' "$INPUT" | jq -r "($1) // empty" 2>/dev/null || true
}

# deny REASON: print the PreToolUse decision that blocks the tool call, with REASON
# encoded by jq so any quote or backslash in it stays text.
deny() {
  jq -cn --arg reason "$1" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
}
