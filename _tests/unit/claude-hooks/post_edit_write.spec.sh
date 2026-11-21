#!/usr/bin/env shellspec
# Unit tests for .claude/hooks/post-edit-write.sh
# Focuses on the action-validator integration added in this PR

HOOK=".claude/hooks/post-edit-write.sh"

# Helper: make_input FILE_PATH
make_input() {
  local file_path="$1"
  printf '{"tool_input":{"file_path":"%s"}}' "$file_path"
}

# Helper: path_with STUB: print a directory for PATH holding only what the hook needs
# (jq and the utilities lib.sh uses) and a stub of STUB that prints "STUB called", so
# an example can leave out exactly the tool it is about.
path_with() {
  local dir="${SHELLSPEC_TMPBASE}/path-with-$1"
  mkdir -p "$dir"
  for _t in jq dirname tr; do ln -sf "$(command -v "$_t")" "$dir/$_t"; done
  printf '#!/bin/sh\nprintf "%s called\\n"\n' "$1" >"$dir/$1"
  chmod +x "$dir/$1"
  printf '%s' "$dir"
}

# Helper: run_hook_on_path DIR INPUT: run the hook with DIR as the whole PATH.
run_hook_on_path() {
  printf '%s' "$2" | PATH="$1" "$(command -v sh)" "$HOOK" 2>&1
}

Describe ".claude/hooks/post-edit-write.sh"

Describe "file path handling"

Context "when file path is empty"
Data
#| {"tool_input":{}}
End
It "exits 0"
When run script "$HOOK"
The status should be success
End
End

Context "when file path does not match any known extension"
It "exits without error for unknown file types"
input=$(make_input "/some/file.txt")
When call hook_run "$HOOK" "$input"
The status should be success
End
End

End

Describe "action-validator integration for action.yml files"

Context "when action-validator is available"
It "calls action-validator on action.yml files"
# We mock action-validator by temporarily placing a mock in PATH
TMPBIN=$(mktemp -d)
printf '#!/bin/sh\nprintf "action-validator called: %%s\n" "$1" >&2\n' >"$TMPBIN/action-validator"
chmod +x "$TMPBIN/action-validator"

input=$(make_input "/myaction/action.yml")
result=$(PATH="$TMPBIN:$PATH" sh "$HOOK" <<<"$input" 2>&1)
rm -rf "$TMPBIN"

When call printf '%s\n' "$result"
The output should include "action-validator called"
The output should include "action.yml"
End
End

Context "when action-validator is not available"
It "skips action-validator gracefully without error"
# PATH holds jq and a stub jactionlint but no action-validator; the stub's output shows the
# hook reached its action.yml checks.
When call run_hook_on_path "$(path_with jactionlint)" "$(make_input "/myaction/action.yml")"
The status should be success
The output should include "jactionlint called"
The output should not include "action-validator"
The output should not include "not found"
End
End

Context "when jactionlint is also available"
It "calls both jactionlint and action-validator on action.yml"
TMPBIN=$(mktemp -d)
printf '#!/bin/sh\nprintf "jactionlint called: %%s\n" "$1" >&2\n' >"$TMPBIN/jactionlint"
printf '#!/bin/sh\nprintf "action-validator called: %%s\n" "$1" >&2\n' >"$TMPBIN/action-validator"
chmod +x "$TMPBIN/jactionlint" "$TMPBIN/action-validator"

input=$(make_input "/myaction/action.yml")
result=$(PATH="$TMPBIN:$PATH" sh "$HOOK" <<<"$input" 2>&1)
rm -rf "$TMPBIN"

When call printf '%s\n' "$result"
The output should include "jactionlint called"
The output should include "action-validator called"
End
End

Context "when action-validator returns a non-zero exit code"
It "continues without failing (uses || true)"
TMPBIN=$(mktemp -d)
printf '#!/bin/sh\nprintf "validation error\n" >&2\nexit 1\n' >"$TMPBIN/action-validator"
# A stub jactionlint keeps the real one from reporting on a file that does not exist.
printf '#!/bin/sh\nexit 0\n' >"$TMPBIN/jactionlint"
chmod +x "$TMPBIN/action-validator" "$TMPBIN/jactionlint"

input=$(make_input "/myaction/action.yml")
PATH="$TMPBIN:$PATH" sh "$HOOK" <<<"$input" >/dev/null 2>&1
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
printf '#!/bin/sh\nprintf "action-validator called\n" >&2\n' >"$TMPBIN/action-validator"
chmod +x "$TMPBIN/action-validator"

input=$(make_input "/myaction/some_script.py")
result=$(PATH="$TMPBIN:$PATH" sh "$HOOK" <<<"$input" 2>&1)
rm -rf "$TMPBIN"

When call printf '%s\n' "$result"
The output should not include "action-validator called"
End
End

Context "when editing a .sh file"
It "does not call action-validator for shell scripts"
TMPBIN=$(mktemp -d)
printf '#!/bin/sh\nprintf "action-validator called\n" >&2\n' >"$TMPBIN/action-validator"
chmod +x "$TMPBIN/action-validator"

input=$(make_input "/myaction/helper.sh")
result=$(PATH="$TMPBIN:$PATH" sh "$HOOK" <<<"$input" 2>&1)
rm -rf "$TMPBIN"

When call printf '%s\n' "$result"
The output should not include "action-validator called"
End
End

Context "when editing a .yml file that is not action.yml"
It "does not call action-validator for arbitrary .yml files"
TMPBIN=$(mktemp -d)
printf '#!/bin/sh\nprintf "action-validator called\n" >&2\n' >"$TMPBIN/action-validator"
chmod +x "$TMPBIN/action-validator"

input=$(make_input "/myaction/config.yml")
result=$(PATH="$TMPBIN:$PATH" sh "$HOOK" <<<"$input" 2>&1)
rm -rf "$TMPBIN"

When call printf '%s\n' "$result"
The output should not include "action-validator called"
End
End

End

Describe "jactionlint is called for action.yml files"

Context "when jactionlint is available"
It "calls jactionlint on action.yml"
TMPBIN=$(mktemp -d)
printf '#!/bin/sh\nprintf "jactionlint called: %%s\n" "$1" >&2\n' >"$TMPBIN/jactionlint"
chmod +x "$TMPBIN/jactionlint"

input=$(make_input "/myaction/action.yml")
result=$(PATH="$TMPBIN:$PATH" sh "$HOOK" <<<"$input" 2>&1)
rm -rf "$TMPBIN"

When call printf '%s\n' "$result"
The output should include "jactionlint called"
End
End

Context "when jactionlint is not available"
It "skips jactionlint gracefully"
# PATH holds jq and a stub action-validator but no jactionlint.
When call run_hook_on_path "$(path_with action-validator)" "$(make_input "/myaction/action.yml")"
The status should be success
The output should include "action-validator called"
The output should not include "jactionlint"
The output should not include "not found"
End
End

End

End
