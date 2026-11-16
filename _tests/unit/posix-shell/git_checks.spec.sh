#!/usr/bin/env shellspec
# Static guard: every run: step that calls git first checks that git exists.
#
# The harness runs steps with the system bin directories on PATH, where git is installed,
# so a step cannot be run with git missing; this reads the steps instead. The _tools
# scripts are not scanned: they check through require_git in _tools/shared.sh.

Describe "git availability checks"
SCANNER="${PROJECT_ROOT}/_tests/unit/posix-shell/find_unchecked_git.py"

# Scans one action whose single sh step runs the given lines as a literal block.
scan_step() {
  printf '%s\n' 'runs:' '  steps:' '    - shell: sh' '      run: |' >"${SHELLSPEC_TMPBASE}/action.yml"
  for line in "$@"; do
    printf '        %s\n' "$line" >>"${SHELLSPEC_TMPBASE}/action.yml"
  done
  _harness_python "$SCANNER" "${SHELLSPEC_TMPBASE}/action.yml"
}

# Scans an action file made of the given lines.
scan_file() {
  printf '%s\n' "$@" >"${SHELLSPEC_TMPBASE}/file.yml"
  _harness_python "$SCANNER" "${SHELLSPEC_TMPBASE}/file.yml"
}

It "precede every git call in every action.yml"
When call _harness_python "$SCANNER" "$PROJECT_ROOT"/*/action.yml "$PROJECT_ROOT"/.github/actions/*/action.yml
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

It "accepts a check that quotes the tool name"
When call scan_step 'command -v "git" >/dev/null 2>&1 || exit 1' 'git status'
The status should be success
The output should equal ""
End

It "reports a quoted command name"
When call scan_step '"git" status'
The status should be failure
The output should include "action.yml:5:"
End

It "skips a step whose shell is not sh or bash"
When call scan_file 'runs:' '  steps:' '    - shell: node {0}' '      run: |' '        execSync(`git status`)'
The status should be success
The output should equal ""
End

It "checks each run: step on its own"
When call scan_file 'runs:' '  steps:' '    - run: |' '        command -v git >/dev/null 2>&1 || exit 1' '        git diff' \
  '    - run: |' '        git status'
The status should be failure
The output should include "file.yml:7:"
The output should not include "file.yml:5:"
End

# A run: value is the decoded YAML scalar: a plain scalar folded over two lines, quotes, and
# escapes such as \t and \x67 (g) all give `git status`.
It "reports a plain run: value folded over two lines"
When call scan_file 'runs:' '  steps:' '    - run: git' '        status'
The status should be failure
The output should include "file.yml:3:"
End

# Parameters applies to every later example in this block, so this one comes last.
Parameters
"git status"
"'git status'"
'"git status"'
'"git\tstatus"'
'"\x67it status"'
End

It "reports a single-line run: value written as $1"
When call scan_file 'runs:' '  steps:' "    - run: $1"
The status should be failure
The output should include "file.yml:3:"
End
End
End
