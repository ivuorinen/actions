#!/usr/bin/env shellspec
# Static guard: every run: step that calls an external tool first checks that it exists.
#
# The tools are the ones .claude/rules/posix-shell.md lists as needing a command -v check;
# the scanner reads them from the rule and parses each run: script with shfmt. The harness
# runs steps with the system bin directories on PATH, where most of them are installed, so a
# step cannot be run with a tool missing; this reads the steps instead. The _tools scripts are
# not scanned: they check git through require_git in _tools/shared.sh.

Describe "tool availability checks"
SCANNER="${PROJECT_ROOT}/_tests/unit/posix-shell/find_unchecked_tools.py"

# Scans one action whose single sh step runs the given lines as a literal block; the first
# line is line 5 of the file.
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
When call scan_step 'make' 'find . -name x' 'unlisted-tool .'
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

It "reads past a wrapper's options and their arguments"
When call scan_step 'command -v sudo >/dev/null 2>&1 || exit 1' 'sudo -u runner docker ps'
The status should be failure
The output should include "action.yml:6: docker is called"
End

It "reads the command timeout runs, past its duration"
When call scan_step 'timeout 10 docker ps'
The status should be failure
The output should include "action.yml:5: docker is called"
End

It "reads the command xargs runs, past its options"
When call scan_step 'printf "%s\n" a | xargs -n 1 git log'
The status should be failure
The output should include "action.yml:5: git is called"
End

It "reads the first word of the code eval runs"
When call scan_step 'eval "gh release view"'
The status should be failure
The output should include "action.yml:5: gh is called"
End

It "reads the command after find -exec"
When call scan_step 'find . -name "*.tf" -exec terraform fmt {} \;'
The status should be failure
The output should include "action.yml:5: terraform is called"
End

It "reads the script sh -c runs"
When call scan_step "sh -c 'docker ps'"
The status should be failure
The output should include "action.yml:5: docker is called"
End

It "reads a here-document fed to sh as a script"
When call scan_step "sh -s <<'EOF'" 'gh release list' 'EOF'
The status should be failure
The output should include "gh is called"
End

It "skips a here-document fed to anything else"
When call scan_step 'command -v python3 >/dev/null 2>&1 || exit 1' "python3 - <<'PY'" 'docker = 1' 'PY'
The status should be success
The output should equal ""
End

It "reads past a redirection before the command"
When call scan_step '>out.txt git status'
The status should be failure
The output should include "action.yml:5: git is called"
End

It "does not take a left shift in arithmetic for a here-document"
When call scan_step 'n=$((x << y))' 'git status'
The status should be failure
The output should include "action.yml:6: git is called"
End

It "reports a call in a command substitution closed on a later line"
When call scan_step 'files=$(' '  git diff --name-only)'
The status should be failure
The output should include "git is called"
End

It "does not take an argument on a continuation line for a call"
When call scan_step 'command -v sudo >/dev/null 2>&1 || exit 1' 'command -v apt-get >/dev/null 2>&1 || exit 1' \
  'sudo apt-get install -y \' '  cmake \' '  zlib1g-dev'
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
When call scan_step 'git status; command -v git >/dev/null 2>&1 || exit 1'
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

It "reads past env's assignments, an expansion in one included"
When call scan_step 'env FOO="$x" docker ps'
The status should be failure
The output should include "action.yml:5: docker is called"
End

It "reads past sudo's assignments"
When call scan_step 'command -v sudo >/dev/null 2>&1 || exit 1' 'sudo FOO=1 docker ps'
The status should be failure
The output should include "action.yml:6: docker is called"
End

It "reads past a long option and its argument"
When call scan_step 'command -v sudo >/dev/null 2>&1 || exit 1' 'sudo --user runner docker ps'
The status should be failure
The output should include "action.yml:6: docker is called"
End

It "reads past a cluster of short options whose last takes an argument"
When call scan_step 'command -v sudo >/dev/null 2>&1 || exit 1' 'sudo -Eu runner docker ps'
The status should be failure
The output should include "action.yml:6: docker is called"
End

It "reads the command time runs"
When call scan_step 'time docker ps'
The status should be failure
The output should include "action.yml:5: docker is called"
End

It "reads the command stdbuf runs"
When call scan_step 'stdbuf -oL docker ps'
The status should be failure
The output should include "action.yml:5: docker is called"
End

It "reads a command named by its path"
When call scan_step '/usr/bin/docker ps'
The status should be failure
The output should include "action.yml:5: docker is called"
End

It "reads the command line env -S splits"
When call scan_step "env -S 'docker ps'"
The status should be failure
The output should include "docker is called"
End

It "reads the command a wrapper after find -exec runs"
When call scan_step 'command -v sudo >/dev/null 2>&1 || exit 1' 'find . -exec sudo terraform fmt {} \;'
The status should be failure
The output should include "action.yml:6: terraform is called"
End

It "reads every statement of the code eval runs"
When call scan_step 'eval "true; gh release view"'
The status should be failure
The output should include "gh is called"
End

It "reads the action trap runs"
When call scan_step "trap 'docker rm -f build' EXIT"
The status should be failure
The output should include "docker is called"
End

It "reads the script sh runs with a cluster of options"
When call scan_step "sh -ec 'docker ps'"
The status should be failure
The output should include "docker is called"
End

It "reads the script a shell named by its path runs"
When call scan_step "/bin/sh -c 'docker ps'"
The status should be failure
The output should include "docker is called"
End

It "reads a here-document piped to sh as a script"
When call scan_step "cat <<'EOF' | sh" 'gh release list' 'EOF'
The status should be failure
The output should include "gh is called"
End

It "reads a command substitution in a data here-document"
When call scan_step 'cat <<EOF' '$(git rev-parse HEAD)' 'EOF'
The status should be failure
The output should include "git is called"
End

It "reads an option argument attached to its option"
When call scan_step 'command -v sudo >/dev/null 2>&1 || exit 1' 'sudo -uroot docker ps'
The status should be failure
The output should include "action.yml:6: docker is called"
End

It "reads past timeout's attached option argument and its duration"
When call scan_step 'timeout -k10s 60 docker ps'
The status should be failure
The output should include "action.yml:5: docker is called"
End

It "reads the script sh -c runs behind a command it does not know"
When call scan_step "ionice -c3 sh -c 'docker ps'"
The status should be failure
The output should include "docker is called"
End

It "reads a script sh -c runs that holds an expansion"
When call scan_step 'sh -c "docker ps $flags"'
The status should be failure
The output should include "docker is called"
End

It "reads eval's code when an operand is an expansion"
When call scan_step 'eval git "$args"'
The status should be failure
The output should include "git is called"
End

It "reads the script a shell runs with -c after -o"
When call scan_step "bash -o pipefail -c 'docker ps'"
The status should be failure
The output should include "docker is called"
End

It "reads trap's action after --"
When call scan_step "trap -- 'docker rm -f build' EXIT"
The status should be failure
The output should include "docker is called"
End

It "reports a parse error in a script a command runs at that command's line"
When call scan_step 'set -eu' 'eval "if then fi"'
The status should be failure
The output should include "action.yml:6: shfmt cannot parse a script this step runs"
End
End

Describe "which checks count"
It "does not count a check that lets the step go on"
When call scan_step 'command -v git >/dev/null 2>&1 || true' 'git status'
The status should be failure
The output should include "action.yml:6: git is called"
End

# exit 0 ends the step without failing it, which skips its work silently.
It "does not count a check that exits 0"
When call scan_step 'command -v git >/dev/null 2>&1 || { echo "no git"; exit 0; }' 'git status'
The status should be failure
The output should include "action.yml:6: git is called"
End

It "does not count if ! command -v whose branch exits without a status"
When call scan_step 'if ! command -v git >/dev/null 2>&1; then' '  echo "no git"' '  exit' 'fi' 'git status'
The status should be failure
The output should include "action.yml:9: git is called"
End

It "does not count if ! command -v when its branch goes on"
When call scan_step 'if ! command -v pnpm >/dev/null 2>&1; then' '  echo "pnpm is missing"' 'fi' 'pnpm install'
The status should be failure
The output should include "action.yml:8: pnpm is called"
End

It "lets if command -v cover its then branch only"
When call scan_step 'if command -v jq >/dev/null 2>&1; then' '  jq . a.json' 'fi' 'jq . b.json'
The status should be failure
The output should include "action.yml:8: jq is called"
End

It "lets command -v ... && cover the command it guards"
When call scan_step 'command -v npm >/dev/null 2>&1 && npm ci'
The status should be success
The output should equal ""
End

It "does not let a check in one case branch cover another"
When call scan_step 'case "$pm" in' '  npm) command -v npm >/dev/null 2>&1 || exit 1; npm ci ;;' '  *) npm ci ;;' 'esac'
The status should be failure
The output should include "action.yml:7: npm is called"
End

It "lets checks in every branch cover what follows"
When call scan_step 'if [ -n "$x" ]; then' '  command -v git >/dev/null 2>&1 || exit 1' 'else' \
  '  command -v git >/dev/null 2>&1 || exit 1' 'fi' 'git status'
The status should be success
The output should equal ""
End

It "does not let a check in a subshell cover what follows"
When call scan_step '(command -v git >/dev/null 2>&1 || exit 1)' 'git status'
The status should be failure
The output should include "action.yml:6: git is called"
End

It "does not let a check in a function body cover what follows"
When call scan_step 'f() { command -v git >/dev/null 2>&1 || exit 1; }' 'git status'
The status should be failure
The output should include "action.yml:6: git is called"
End

It "does not let a check run in the background cover what follows"
When call scan_step 'command -v git >/dev/null 2>&1 || exit 1 &' 'git status'
The status should be failure
The output should include "action.yml:6: git is called"
End

It "does not take a quoted * pattern for the default case"
When call scan_step 'case "$x" in' '  a) command -v git >/dev/null 2>&1 || exit 1 ;;' \
  '  "*") command -v git >/dev/null 2>&1 || exit 1 ;;' 'esac' 'git status'
The status should be failure
The output should include "action.yml:9: git is called"
End

It "lets checks in every case branch, the default one included, cover what follows"
When call scan_step 'case "$x" in' '  a) command -v git >/dev/null 2>&1 || exit 1 ;;' \
  '  *) command -v git >/dev/null 2>&1 || exit 1 ;;' 'esac' 'git status'
The status should be success
The output should equal ""
End
End

Describe "the action file"
It "fails on a script shfmt cannot parse"
When call scan_step 'if then fi'
The status should be failure
The output should include "shfmt cannot parse this script"
End

It "reads the command a nick-fields/retry step runs"
When call scan_file 'runs:' '  steps:' '    - uses: nick-fields/retry@0000000000000000000000000000000000000000' \
  '      with:' '        command: |' '          git status'
The status should be failure
The output should include "file.yml:6: git is called"
End

It "reads the other scripts a nick-fields/retry step runs, whatever the action's case"
When call scan_file 'runs:' '  steps:' '    - uses: Nick-Fields/Retry@0000000000000000000000000000000000000000' \
  '      with:' '        command: echo ok' '        new_command_on_retry: |' '          git status'
The status should be failure
The output should include "file.yml:7: git is called"
End

It "reports a file that is not YAML"
When call scan_file 'runs: [' '  steps'
The status should be failure
The output should include "cannot be read as YAML"
End

It "reads a step whose shell is named by its path"
When call scan_file 'runs:' '  steps:' '    - shell: /bin/sh' '      run: |' '        git status'
The status should be failure
The output should include "file.yml:5: git is called"
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
