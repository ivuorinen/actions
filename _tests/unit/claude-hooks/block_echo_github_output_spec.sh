#!/usr/bin/env shellspec
# Unit tests for .claude/hooks/block-echo-github-output.sh
# Tests that the hook blocks echo-based writes to GITHUB_OUTPUT

HOOK=".claude/hooks/block-echo-github-output.sh"

# Helper: make_input FILE_PATH CONTENT
make_input() {
  local file_path="$1"
  local content="$2"
  printf '{"tool_input":{"file_path":"%s","new_string":%s}}' \
    "$file_path" \
    "$(printf '%s' "$content" | jq -Rs .)"
}

# Helper: make_write_input FILE_PATH CONTENT
# Simulates a Write tool call (uses "content" key instead of "new_string")
make_write_input() {
  local file_path="$1"
  local content="$2"
  printf '{"tool_input":{"file_path":"%s","content":%s}}' \
    "$file_path" \
    "$(printf '%s' "$content" | jq -Rs .)"
}

Describe ".claude/hooks/block-echo-github-output.sh"

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

    Context "when file path is a Python file"
      It "ignores non-action/workflow files"
        input=$(make_input "/some/script.py" 'echo "key=value" >> "$GITHUB_OUTPUT"')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should equal ""
      End
    End

    Context "when file path is a plain shell script (.sh)"
      It "ignores .sh files (only action.yml and workflow files are checked)"
        input=$(make_input "/some/script.sh" 'echo "key=value" >> "$GITHUB_OUTPUT"')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should equal ""
      End
    End

    Context "when file path is an action.yml"
      It "checks action.yml files"
        input=$(make_input "/myaction/action.yml" 'echo "key=value" >> "$GITHUB_OUTPUT"')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include "deny"
      End
    End

    Context "when file path is a workflow .yml file"
      It "checks .github/workflows/*.yml files"
        input=$(make_input "/repo/.github/workflows/ci.yml" 'echo "key=value" >> "$GITHUB_OUTPUT"')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include "deny"
      End
    End

    Context "when file path is a workflow .yaml file"
      It "checks .github/workflows/*.yaml files"
        input=$(make_input "/repo/.github/workflows/release.yaml" 'echo "key=value" >> "$GITHUB_OUTPUT"')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include "deny"
      End
    End

  End

  Describe "echo to GITHUB_OUTPUT detection"

    Context "when content uses echo with >> GITHUB_OUTPUT"
      It "blocks echo key=value >> GITHUB_OUTPUT"
        input=$(make_input "/myaction/action.yml" 'echo "version=$VERSION" >> "$GITHUB_OUTPUT"')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include '"permissionDecision":"deny"'
      End

      It "includes remediation message in reason"
        input=$(make_input "/myaction/action.yml" 'echo "version=$VERSION" >> "$GITHUB_OUTPUT"')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include "printf"
        The output should include "GITHUB_OUTPUT"
      End

      It "blocks echo without quoted variable"
        input=$(make_input "/myaction/action.yml" 'echo key=value >> $GITHUB_OUTPUT')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include '"permissionDecision":"deny"'
      End

      It "blocks echo with variable expansion in key"
        input=$(make_input "/myaction/action.yml" 'echo "${KEY}=${VALUE}" >> "$GITHUB_OUTPUT"')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include '"permissionDecision":"deny"'
      End
    End

    Context "when content uses printf instead of echo"
      It "allows printf format for GITHUB_OUTPUT"
        input=$(make_input "/myaction/action.yml" 'printf "version=%s\n" "$VERSION" >> "$GITHUB_OUTPUT"')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should equal ""
      End

      It "allows printf with key=value format"
        input=$(make_input "/myaction/action.yml" "printf 'key=%s\n' \"\$value\" >> \"\$GITHUB_OUTPUT\"")
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should equal ""
      End
    End

    Context "when content has no GITHUB_OUTPUT writes"
      It "allows content without GITHUB_OUTPUT"
        input=$(make_input "/myaction/action.yml" 'echo "Processing..."
printf "%s\n" "Done"')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should equal ""
      End
    End

    Context "when content is empty"
      Data
        | '{"tool_input":{"file_path":"/myaction/action.yml","new_string":""}}'
      End
      It "exits 0 without output"
        When run script "$HOOK"
        The status should be success
        The output should equal ""
      End
    End

  End

  Describe "Write tool input (content key)"

    Context "when Write tool is used with echo >> GITHUB_OUTPUT"
      It "also checks content key from Write tool"
        input=$(make_write_input "/myaction/action.yml" 'echo "result=true" >> "$GITHUB_OUTPUT"')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include '"permissionDecision":"deny"'
      End
    End

    Context "when Write tool uses printf"
      It "allows Write tool with printf format"
        input=$(make_write_input "/myaction/action.yml" 'printf "result=%s\n" "true" >> "$GITHUB_OUTPUT"')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should equal ""
      End
    End

  End

  Describe "output format"

    Context "when echo >> GITHUB_OUTPUT is detected"
      It "outputs valid JSON with deny decision"
        input=$(make_input "/myaction/action.yml" 'echo "key=value" >> "$GITHUB_OUTPUT"')
        When run bash -c "printf '%s' '$input' | sh '$HOOK' | jq -e '.hookSpecificOutput.permissionDecision'"
        The output should include "deny"
      End

      It "includes hookEventName PreToolUse"
        input=$(make_input "/myaction/action.yml" 'echo "key=value" >> "$GITHUB_OUTPUT"')
        When run bash -c "printf '%s' '$input' | sh '$HOOK' | jq -r '.hookSpecificOutput.hookEventName'"
        The output should include "PreToolUse"
      End

      It "provides printf as the fix in the reason"
        input=$(make_input "/myaction/action.yml" 'echo "key=value" >> "$GITHUB_OUTPUT"')
        When run bash -c "printf '%s' '$input' | sh '$HOOK' | jq -r '.hookSpecificOutput.permissionDecisionReason'"
        The output should include "printf"
      End
    End

  End

  Describe "edge cases"

    Context "when echo appears in comments only"
      It "still blocks if echo >> GITHUB_OUTPUT matches in non-comment lines"
        input=$(make_input "/myaction/action.yml" '# echo "old=value" >> "$GITHUB_OUTPUT"
echo "active=value" >> "$GITHUB_OUTPUT"')
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include "deny"
      End
    End

    Context "when file path uses filePath (camelCase) key"
      It "handles filePath key in JSON input"
        input=$(printf '{"tool_input":{"filePath":"/myaction/action.yml","new_string":%s}}' \
          "$(printf 'echo "k=v" >> "$GITHUB_OUTPUT"' | jq -Rs .)")
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should include "deny"
      End
    End

  End

End