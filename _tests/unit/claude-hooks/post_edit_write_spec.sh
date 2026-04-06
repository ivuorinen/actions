#!/usr/bin/env shellspec
# Unit tests for .claude/hooks/post-edit-write.sh
# Focuses on the action-validator integration added in this PR

HOOK=".claude/hooks/post-edit-write.sh"

# Helper: make_input FILE_PATH
make_input() {
  local file_path="$1"
  printf '{"tool_input":{"file_path":"%s"}}' "$file_path"
}

Describe ".claude/hooks/post-edit-write.sh"

  Describe "file path handling"

    Context "when file path is empty"
      Data
        | '{"tool_input":{}}'
      End
      It "exits 0"
        When run script "$HOOK"
        The status should be success
      End
    End

    Context "when file path does not match any known extension"
      It "exits without error for unknown file types"
        input=$(make_input "/some/file.txt")
        When run bash -c "printf '%s' '$input' | sh '$HOOK'"
        The status should be success
      End
    End

  End

  Describe "action-validator integration for action.yml files"

    Context "when action-validator is available"
      It "calls action-validator on action.yml files"
        # We mock action-validator by temporarily placing a mock in PATH
        TMPBIN=$(mktemp -d)
        printf '#!/bin/sh\nprintf "action-validator called: %%s\n" "$1" >&2\n' > "$TMPBIN/action-validator"
        chmod +x "$TMPBIN/action-validator"

        input=$(make_input "/myaction/action.yml")
        result=$(PATH="$TMPBIN:$PATH" sh "$HOOK" <<< "$input" 2>&1)
        rm -rf "$TMPBIN"

        When run bash -c "printf '%s\n' '$result'"
        The output should include "action-validator called"
        The output should include "action.yml"
      End
    End

    Context "when action-validator is not available"
      It "skips action-validator gracefully without error"
        # Remove action-validator from PATH by using a clean PATH
        input=$(make_input "/myaction/action.yml")
        # Use PATH that only has basic utilities, no action-validator
        result=$(PATH="/usr/bin:/bin" sh "$HOOK" <<< "$input" 2>&1 || true)

        When run bash -c "printf '%s\n' '$result'; exit 0"
        # Should not contain an error about action-validator being missing
        The output should not include "command not found"
        The output should not include "action-validator: not found"
      End
    End

    Context "when actionlint is also available"
      It "calls both actionlint and action-validator on action.yml"
        TMPBIN=$(mktemp -d)
        printf '#!/bin/sh\nprintf "actionlint called: %%s\n" "$1" >&2\n' > "$TMPBIN/actionlint"
        printf '#!/bin/sh\nprintf "action-validator called: %%s\n" "$1" >&2\n' > "$TMPBIN/action-validator"
        chmod +x "$TMPBIN/actionlint" "$TMPBIN/action-validator"

        input=$(make_input "/myaction/action.yml")
        result=$(PATH="$TMPBIN:$PATH" sh "$HOOK" <<< "$input" 2>&1)
        rm -rf "$TMPBIN"

        When run bash -c "printf '%s\n' '$result'"
        The output should include "actionlint called"
        The output should include "action-validator called"
      End
    End

    Context "when action-validator returns a non-zero exit code"
      It "continues without failing (uses || true)"
        TMPBIN=$(mktemp -d)
        printf '#!/bin/sh\nprintf "validation error\n" >&2\nexit 1\n' > "$TMPBIN/action-validator"
        chmod +x "$TMPBIN/action-validator"

        input=$(make_input "/myaction/action.yml")
        PATH="$TMPBIN:$PATH" sh "$HOOK" <<< "$input" 2>/dev/null
        exit_code=$?
        rm -rf "$TMPBIN"

        When run bash -c "exit $exit_code"
        The status should be success
      End
    End

  End

  Describe "action-validator is NOT called for non-action.yml files"

    Context "when editing a .py file"
      It "does not call action-validator for Python files"
        TMPBIN=$(mktemp -d)
        called=0
        printf '#!/bin/sh\nprintf "action-validator called\n" >&2\n' > "$TMPBIN/action-validator"
        chmod +x "$TMPBIN/action-validator"

        input=$(make_input "/myaction/some_script.py")
        result=$(PATH="$TMPBIN:$PATH" sh "$HOOK" <<< "$input" 2>&1)
        rm -rf "$TMPBIN"

        When run bash -c "printf '%s\n' '$result'"
        The output should not include "action-validator called"
      End
    End

    Context "when editing a .sh file"
      It "does not call action-validator for shell scripts"
        TMPBIN=$(mktemp -d)
        printf '#!/bin/sh\nprintf "action-validator called\n" >&2\n' > "$TMPBIN/action-validator"
        chmod +x "$TMPBIN/action-validator"

        input=$(make_input "/myaction/helper.sh")
        result=$(PATH="$TMPBIN:$PATH" sh "$HOOK" <<< "$input" 2>&1)
        rm -rf "$TMPBIN"

        When run bash -c "printf '%s\n' '$result'"
        The output should not include "action-validator called"
      End
    End

    Context "when editing a .yml file that is not action.yml"
      It "does not call action-validator for arbitrary .yml files"
        TMPBIN=$(mktemp -d)
        printf '#!/bin/sh\nprintf "action-validator called\n" >&2\n' > "$TMPBIN/action-validator"
        chmod +x "$TMPBIN/action-validator"

        input=$(make_input "/myaction/config.yml")
        result=$(PATH="$TMPBIN:$PATH" sh "$HOOK" <<< "$input" 2>&1)
        rm -rf "$TMPBIN"

        When run bash -c "printf '%s\n' '$result'"
        The output should not include "action-validator called"
      End
    End

  End

  Describe "actionlint is called for action.yml files"

    Context "when actionlint is available"
      It "calls actionlint on action.yml"
        TMPBIN=$(mktemp -d)
        printf '#!/bin/sh\nprintf "actionlint called: %%s\n" "$1" >&2\n' > "$TMPBIN/actionlint"
        chmod +x "$TMPBIN/actionlint"

        input=$(make_input "/myaction/action.yml")
        result=$(PATH="$TMPBIN:$PATH" sh "$HOOK" <<< "$input" 2>&1)
        rm -rf "$TMPBIN"

        When run bash -c "printf '%s\n' '$result'"
        The output should include "actionlint called"
      End
    End

    Context "when actionlint is not available"
      It "skips actionlint gracefully"
        input=$(make_input "/myaction/action.yml")
        result=$(PATH="/usr/bin:/bin" sh "$HOOK" <<< "$input" 2>&1 || true)

        When run bash -c "printf '%s\n' '$result'; exit 0"
        The output should not include "actionlint: not found"
        The output should not include "command not found"
      End
    End

  End

End