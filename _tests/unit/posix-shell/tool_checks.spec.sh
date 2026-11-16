#!/usr/bin/env shellspec
# Static guard: every run: step that calls an external tool first checks that it exists.
#
# The tools are the ones .claude/rules/posix-shell.md lists as needing a command -v check;
# the scanner reads them from the rule. The harness runs steps with the system bin
# directories on PATH, where most of them are installed, so a step cannot be run with a tool
# missing; this reads the steps instead. The _tools scripts are not scanned: they check git
# through require_git in _tools/shared.sh.

Describe "tool availability checks"
SCANNER="${PROJECT_ROOT}/_tests/unit/posix-shell/find_unchecked_tools.py"

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

It "precede every tool call in every action.yml"
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

It "checks every tool the rule lists, not only git"
When call scan_step "error_count=\$(jq '.runs | length' report.sarif)"
The status should be failure
The output should include "action.yml:5: jq is called before \`command -v jq\`"
End

It "reports the first unchecked call of each tool"
When call scan_step 'npm ci' 'docker build .'
The status should be failure
The output should include "action.yml:5: npm is called"
The output should include "action.yml:6: docker is called"
End

It "does not check a POSIX utility or a tool the rule does not list"
When call scan_step 'make' 'find . -name x' 'eslint .'
The status should be success
The output should equal ""
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

It "does not take a value for a call"
When call scan_step 'manager="npm"' 'tool=docker'
The status should be success
The output should equal ""
End

It "does not take a case pattern for a call"
When call scan_step 'case "$pm" in' '  "pnpm") echo p ;;' '  bun|npm)' '    echo n' '    ;;' 'esac'
The status should be success
The output should equal ""
End

It "reads the command that set -- builds for \"\$@\" to run"
When call scan_step 'set -- npx --no-install eslint' '"$@"'
The status should be failure
The output should include "action.yml:5: npx is called"
End

It "reports the command a wrapper runs"
When call scan_step 'command -v sudo >/dev/null 2>&1 || exit 1' 'sudo apt-get update'
The status should be failure
The output should include "action.yml:6: apt-get is called"
The output should not include "sudo is called"
End

It "does not take an argument on a continuation line for a call"
When call scan_step 'command -v sudo >/dev/null 2>&1 || exit 1' 'command -v apt-get >/dev/null 2>&1 || exit 1' \
  'sudo apt-get install -y \' '  cmake \' '  zlib1g-dev'
The status should be success
The output should equal ""
End

It "skips a here-document body"
When call scan_step 'command -v python3 >/dev/null 2>&1 || exit 1' "python3 - <<'PY'" 'docker = 1' 'PY'
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

It "reads run: only as a step's script, not as an env variable"
When call scan_file 'runs:' '  steps:' '    - shell: sh' '      env:' '        run: git status' '      run: echo ok'
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
