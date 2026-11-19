#!/usr/bin/env shellspec
# Unit tests for .claude/hooks/lib.sh, through every hook that sources it

Describe ".claude/hooks/lib.sh"

Describe "without jq"
# lib.sh stops every hook, rather than letting the tool call through unchecked.
Parameters
".claude/hooks/block-bashisms.sh"
".claude/hooks/block-echo-github-output.sh"
".claude/hooks/block-generated-validators.sh"
".claude/hooks/block-readme-edits.sh"
".claude/hooks/post-edit-write.sh"
".claude/hooks/route-bash-to-context-mode.sh"
End

It "stops $1 and names jq"
nojq="${SHELLSPEC_TMPBASE}/nojq-bin"
mkdir -p "$nojq"
for _t in dirname tr grep sed; do ln -sf "$(command -v "$_t")" "$nojq/$_t"; done
When run env PATH="$nojq" "$(command -v sh)" "$1"
The status should equal 2
The stdout should equal ""
The stderr should include "jq is required"
End
End

Describe "PreToolUse input that is not JSON"
# A PreToolUse hook cannot check fields it cannot read, so it denies the call.
Parameters
".claude/hooks/block-bashisms.sh"
".claude/hooks/block-echo-github-output.sh"
".claude/hooks/block-generated-validators.sh"
".claude/hooks/block-readme-edits.sh"
".claude/hooks/route-bash-to-context-mode.sh"
End

It "is denied by $1"
When call hook_field "$1" "not json" .hookSpecificOutput.permissionDecision
The status should be success
The output should equal "deny"
End
End

Describe "PreToolUse input that is not exactly one JSON object"
# jq reads a stream of values; a check must see the one object Claude Code sends.
Parameters
'{} {"tool_input":{"command":"git push"}}'
''
'[]'
'"git push"'
'1'
End

It "is denied: [$1]"
When call hook_field ".claude/hooks/route-bash-to-context-mode.sh" "$1" .hookSpecificOutput.permissionDecision
The status should be success
The output should equal "deny"
End
End

Describe "deny"
It "keeps quotes, backslashes and line breaks in the reason as text"
reason=$(printf 'a "quote", a \\backslash and\na line break')
When call sh -c '. .claude/hooks/lib.sh && deny "$1" | jq -r .hookSpecificOutput.permissionDecisionReason' _ "$reason"
The status should be success
The output should equal "$reason"
End
End

End
