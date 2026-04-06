#!/usr/bin/env shellspec
# Unit tests for .claude/hooks/block-readme-edits.sh
# Tests that the hook blocks direct edits to auto-generated action READMEs

HOOK=".claude/hooks/block-readme-edits.sh"

# Helper: make_input FILE_PATH
# Builds JSON input simulating an Edit/Write tool call
make_input() {
  local file_path="$1"
  printf '{"tool_input":{"file_path":"%s","new_string":"# Updated content"}}' "$file_path"
}

Describe ".claude/hooks/block-readme-edits.sh"

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

    Context "when file path is not a README.md"
      It "ignores non-README files"
        input=$(make_input "/some/action.yml")
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should equal ""
      End

      It "ignores other markdown files"
        input=$(make_input "/some/CONTRIBUTING.md")
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should equal ""
      End

      It "ignores readme files in non-action directories"
        input=$(make_input "/project/docs/README.md")
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The output should equal ""
      End
    End

  End

  Describe "action README detection"

    Context "when README.md is in a directory with action.yml"
      It "blocks the edit"
        # Create a temp directory with an action.yml to simulate an action directory
        TMPDIR=$(mktemp -d)
        touch "$TMPDIR/action.yml"
        input=$(printf '{"tool_input":{"file_path":"%s/README.md","new_string":"# Updated"}}' "$TMPDIR")
        result=$(printf '%s' "$input" | sh "$HOOK")
        rm -rf "$TMPDIR"
        When run bash -c "printf '%s' '$result'"
        The output should include '"permissionDecision":"deny"'
      End

      It "includes auto-generated message in deny reason"
        TMPDIR=$(mktemp -d)
        touch "$TMPDIR/action.yml"
        input=$(printf '{"tool_input":{"file_path":"%s/README.md","new_string":"# Updated"}}' "$TMPDIR")
        result=$(printf '%s' "$input" | sh "$HOOK")
        rm -rf "$TMPDIR"
        When run bash -c "printf '%s' '$result'"
        The output should include "auto-generated"
        The output should include "action-docs"
      End

      It "recommends make docs instead"
        TMPDIR=$(mktemp -d)
        touch "$TMPDIR/action.yml"
        input=$(printf '{"tool_input":{"file_path":"%s/README.md","new_string":"# Updated"}}' "$TMPDIR")
        result=$(printf '%s' "$input" | sh "$HOOK")
        rm -rf "$TMPDIR"
        When run bash -c "printf '%s' '$result'"
        The output should include "make docs"
      End
    End

    Context "when README.md is in a directory with action.yaml (alternate extension)"
      It "blocks the edit for action.yaml too"
        TMPDIR=$(mktemp -d)
        touch "$TMPDIR/action.yaml"
        input=$(printf '{"tool_input":{"file_path":"%s/README.md","new_string":"# Updated"}}' "$TMPDIR")
        result=$(printf '%s' "$input" | sh "$HOOK")
        rm -rf "$TMPDIR"
        When run bash -c "printf '%s' '$result'"
        The output should include '"permissionDecision":"deny"'
      End
    End

    Context "when README.md is in a directory WITHOUT action.yml"
      It "allows the edit (not an action README)"
        TMPDIR=$(mktemp -d)
        # No action.yml created - this is a regular directory
        input=$(printf '{"tool_input":{"file_path":"%s/README.md","new_string":"# Updated"}}' "$TMPDIR")
        result=$(printf '%s' "$input" | sh "$HOOK")
        rm -rf "$TMPDIR"
        When run bash -c "printf '%s' '$result'"
        The output should equal ""
      End
    End

    Context "when README.md path uses filePath camelCase key"
      It "handles filePath key in JSON input"
        TMPDIR=$(mktemp -d)
        touch "$TMPDIR/action.yml"
        input=$(printf '{"tool_input":{"filePath":"%s/README.md","new_string":"# Updated"}}' "$TMPDIR")
        result=$(printf '%s' "$input" | sh "$HOOK")
        rm -rf "$TMPDIR"
        When run bash -c "printf '%s' '$result'"
        The output should include '"permissionDecision":"deny"'
      End
    End

  End

  Describe "output format"

    Context "when a README edit is blocked"
      It "outputs valid JSON"
        TMPDIR=$(mktemp -d)
        touch "$TMPDIR/action.yml"
        input=$(printf '{"tool_input":{"file_path":"%s/README.md","new_string":"# Updated"}}' "$TMPDIR")
        result=$(printf '%s' "$input" | sh "$HOOK" | jq -e '.hookSpecificOutput.permissionDecision' 2>/dev/null)
        rm -rf "$TMPDIR"
        When run bash -c "printf '%s' '$result'"
        The output should include "deny"
      End

      It "includes hookEventName PreToolUse"
        TMPDIR=$(mktemp -d)
        touch "$TMPDIR/action.yml"
        input=$(printf '{"tool_input":{"file_path":"%s/README.md","new_string":"# Updated"}}' "$TMPDIR")
        result=$(printf '%s' "$input" | sh "$HOOK" | jq -r '.hookSpecificOutput.hookEventName' 2>/dev/null)
        rm -rf "$TMPDIR"
        When run bash -c "printf '%s' '$result'"
        The output should include "PreToolUse"
      End
    End

  End

  Describe "edge cases"

    Context "when README.md is at repository root (no action.yml at root)"
      It "allows editing root README.md"
        # The root-level README.md typically doesn't have a sibling action.yml
        # We simulate this by using a temp dir without action.yml
        TMPDIR=$(mktemp -d)
        input=$(printf '{"tool_input":{"file_path":"%s/README.md","new_string":"# Root readme"}}' "$TMPDIR")
        result=$(printf '%s' "$input" | sh "$HOOK")
        rm -rf "$TMPDIR"
        When run bash -c "printf '%s' '$result'"
        The output should equal ""
      End
    End

    Context "when both action.yml and action.yaml exist"
      It "blocks the edit (action.yml takes precedence in check)"
        TMPDIR=$(mktemp -d)
        touch "$TMPDIR/action.yml"
        touch "$TMPDIR/action.yaml"
        input=$(printf '{"tool_input":{"file_path":"%s/README.md","new_string":"# Updated"}}' "$TMPDIR")
        result=$(printf '%s' "$input" | sh "$HOOK")
        rm -rf "$TMPDIR"
        When run bash -c "printf '%s' '$result'"
        The output should include '"permissionDecision":"deny"'
      End
    End

  End

End