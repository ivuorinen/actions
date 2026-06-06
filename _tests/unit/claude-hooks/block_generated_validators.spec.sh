#!/usr/bin/env shellspec
# Unit tests for .claude/hooks/block-generated-validators.sh
# Tests that the hook blocks direct edits to generated validate.py files.

HOOK=".claude/hooks/block-generated-validators.sh"

make_input() {
  _mi_file_path="$1"
  _mi_content="$2"
  printf '{"tool_input":{"file_path":"%s","new_string":%s}}' \
    "$_mi_file_path" \
    "$(printf '%s' "$_mi_content" | jq -Rs .)"
}

Describe ".claude/hooks/block-generated-validators.sh"

Describe "file path filtering"

Context "when file path is empty"
Data
#| {"tool_input":{}}
End
It "exits 0 without output"
When run script "$HOOK"
The status should be success
The output should equal ""
End
End

Context "when file path is a generated validate.py"
It "blocks the edit"
input=$(make_input "ansible-lint-fix/validate.py" "print('x')")
When run bash -c "printf '%s' '$input' | sh '$HOOK'"
The status should be success
The output should include "deny"
End
End

Context "when file path is a deeply nested validate.py"
It "blocks regardless of nesting depth"
input=$(make_input "some/nested/action/validate.py" "content")
When run bash -c "printf '%s' '$input' | sh '$HOOK'"
The status should be success
The output should include "deny"
End
End

Context "when file path is not a generated validate.py"
It "allows edits to action.yml"
input=$(make_input "ansible-lint-fix/action.yml" "name: test")
When run bash -c "printf '%s' '$input' | sh '$HOOK'"
The status should be success
The output should equal ""
End

It "allows edits to the generator and kit sources"
input=$(make_input "_validation/generate.py" "content")
When run bash -c "printf '%s' '$input' | sh '$HOOK'"
The status should be success
The output should equal ""
End

It "allows edits to files merely containing validate in the name"
input=$(make_input "_tests/shared/validation_core.py" "content")
When run bash -c "printf '%s' '$input' | sh '$HOOK'"
The status should be success
The output should equal ""
End
End

End

Describe "deny response format"

Context "when blocking a validate.py edit"
It "returns permissionDecision deny in JSON"
input=$(make_input "action/validate.py" "content")
When run bash -c "printf '%s' '$input' | sh '$HOOK' | jq -r '.hookSpecificOutput.permissionDecision'"
The status should be success
The output should equal "deny"
End

It "returns hookEventName PreToolUse"
input=$(make_input "action/validate.py" "content")
When run bash -c "printf '%s' '$input' | sh '$HOOK' | jq -r '.hookSpecificOutput.hookEventName'"
The status should be success
The output should equal "PreToolUse"
End

It "includes make update-validators in the reason"
input=$(make_input "action/validate.py" "content")
When run bash -c "printf '%s' '$input' | sh '$HOOK' | jq -r '.hookSpecificOutput.permissionDecisionReason'"
The status should be success
The output should include "update-validators"
End
End

End

End
