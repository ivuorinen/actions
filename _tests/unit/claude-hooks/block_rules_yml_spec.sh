#!/usr/bin/env shellspec
# Unit tests for .claude/hooks/block-rules-yml.sh
# Tests that the hook blocks direct edits to rules.yml files

HOOK=".claude/hooks/block-rules-yml.sh"

make_input() {
  _mi_file_path="$1"
  _mi_content="$2"
  printf '{"tool_input":{"file_path":"%s","new_string":%s}}' \
    "$_mi_file_path" \
    "$(printf '%s' "$_mi_content" | jq -Rs .)"
}

Describe ".claude/hooks/block-rules-yml.sh"

  Describe "file path filtering"

    Context "when file path is empty"
      Data
        | '{"tool_input":{}}'
      End
      It "exits 0 without output"
        When run script "$HOOK"
        The status should be success
        The output should equal ""
      End
    End

    Context "when file path is a rules.yml"
      It "blocks the edit"
        input=$(make_input "ansible-lint-fix/rules.yml" "rules: []")
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The status should be success
        The output should include "deny"
      End
    End

    Context "when file path is a deeply nested rules.yml"
      It "blocks regardless of nesting depth"
        input=$(make_input "some/nested/action/rules.yml" "content")
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The status should be success
        The output should include "deny"
      End
    End

    Context "when file path is not a rules.yml"
      It "allows edits to action.yml"
        input=$(make_input "ansible-lint-fix/action.yml" "name: test")
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The status should be success
        The output should equal ""
      End

      It "allows edits to other yml files"
        input=$(make_input "some/config.yml" "key: value")
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The status should be success
        The output should equal ""
      End

      It "allows edits to files named rules-custom.yml"
        input=$(make_input "action/rules-custom.yml" "content")
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The status should be success
        The output should equal ""
      End
    End

  End

  Describe "deny response format"

    Context "when blocking a rules.yml edit"
      It "returns permissionDecision deny in JSON"
        input=$(make_input "action/rules.yml" "content")
        When run bash -c "printf '%s' '$input' | sh '$HOOK' | jq -r '.hookSpecificOutput.permissionDecision'"
        The status should be success
        The output should equal "deny"
      End

      It "returns hookEventName PreToolUse"
        input=$(make_input "action/rules.yml" "content")
        When run bash -c "printf '%s' '$input' | sh '$HOOK' | jq -r '.hookSpecificOutput.hookEventName'"
        The status should be success
        The output should equal "PreToolUse"
      End

      It "includes make update-validators in the reason"
        input=$(make_input "action/rules.yml" "content")
        When run bash -c "printf '%s' '$input' | sh '$HOOK' | jq -r '.hookSpecificOutput.permissionDecisionReason'"
        The status should be success
        The output should include "update-validators"
      End
    End

  End

End
