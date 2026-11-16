#!/usr/bin/env shellspec
# Static guard: every run: step that calls git first checks that git exists.
#
# The harness runs steps with the system bin directories on PATH, where git is installed,
# so a step cannot be run with git missing; this reads the steps instead. The _tools
# scripts are not scanned: they check through require_git in _tools/shared.sh.

Describe "git availability checks"
SCANNER="${PROJECT_ROOT}/_tests/unit/posix-shell/find_unchecked_git.py"

# Scans one action whose single step runs the given lines.
scan_step() {
  printf '%s\n' 'runs:' '  steps:' '    - shell: sh' '      run: |' >"${SHELLSPEC_TMPBASE}/action.yml"
  for line in "$@"; do
    printf '        %s\n' "$line" >>"${SHELLSPEC_TMPBASE}/action.yml"
  done
  python3 "$SCANNER" "${SHELLSPEC_TMPBASE}/action.yml"
}

It "precede every git call in every action.yml"
When run python3 "$SCANNER" "$PROJECT_ROOT"/*/action.yml "$PROJECT_ROOT"/.github/actions/*/action.yml
The status should be success
The output should equal ""
End

Describe "the scanner"
It "reports a git call with no check before it"
When call scan_step 'set -eu' 'count=$(git diff --name-only | wc -l)'
The status should be failure
The output should include "action.yml:6: git is called before"
End

It "reports a check that comes after the call"
When call scan_step 'git status' 'command -v git >/dev/null 2>&1 || exit 1'
The status should be failure
The output should include "action.yml:5:"
End

It "accepts a check before the call"
When call scan_step 'command -v git >/dev/null 2>&1 || { echo "::error::git is required"; exit 1; }' 'git diff'
The status should be success
The output should equal ""
End

It "accepts the if ! command -v form"
When call scan_step 'if ! command -v git >/dev/null 2>&1; then' '  exit 1' 'fi' 'git rev-parse HEAD'
The status should be success
The output should equal ""
End

It "ignores git in comments and inside other words"
When call scan_step '# git diff counts the files' 'gitleaks detect' 'ls .git' 'echo "::notice::git fetch skipped"'
The status should be success
The output should equal ""
End

It "reads a quoted hash as text, not as the start of a comment"
When call scan_step "printf '%s\n' 'see # note'; git status"
The status should be failure
The output should include "action.yml:5:"
End

It "does not take a quoted check for a check"
When call scan_step "printf '%s\n' 'command -v git'" 'git status'
The status should be failure
The output should include "action.yml:6:"
End

It "reports a call before a check on the same line"
When call scan_step 'git status; command -v git >/dev/null 2>&1'
The status should be failure
The output should include "action.yml:5:"
End

It "reports a call in a command substitution inside double quotes"
When call scan_step 'files="$(git diff --name-only)"'
The status should be failure
The output should include "action.yml:5:"
End

It "reports a single-line run: value"
printf '%s\n' 'runs:' '  steps:' '    - run: git fetch' >"${SHELLSPEC_TMPBASE}/inline.yml"
When run python3 "$SCANNER" "${SHELLSPEC_TMPBASE}/inline.yml"
The status should be failure
The output should include "inline.yml:3:"
End

It "checks each run: block on its own"
printf '%s\n' 'runs:' '  steps:' '    - run: |' '        command -v git >/dev/null 2>&1 || exit 1' '        git diff' \
  '    - run: |' '        git status' >"${SHELLSPEC_TMPBASE}/two.yml"
When run python3 "$SCANNER" "${SHELLSPEC_TMPBASE}/two.yml"
The status should be failure
The output should include "two.yml:7:"
The output should not include "two.yml:5:"
End
End
End
