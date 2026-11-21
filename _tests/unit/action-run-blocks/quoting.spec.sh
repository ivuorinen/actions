#!/usr/bin/env shellspec
# Static check across every composite action and workflow: a run: block quotes its
# variables, unless it is a deliberate split between `set -f` and `set +f`.

Describe "composite action and workflow run: blocks"
CHECKER="${PROJECT_ROOT}/_tests/unit/action-run-blocks/check_quoting.py"

before() {
  shellspec_setup_test_env "action-run-blocks-$$"
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "action-run-blocks-$$"
}
AfterEach 'after'

# Writes a one-step composite action whose run: block holds the given lines.
fixture_action() {
  mkdir -p fixture/sample
  {
    cat <<'EOF'
name: sample
description: sample
runs:
  using: composite
  steps:
    - name: step
      shell: sh
      run: |
        set -eu
        list="$1"
EOF
    for line in "$@"; do
      printf '        %s\n' "$line"
    done
  } >fixture/sample/action.yml
}

# fixture_workflow DIR WORKFLOW_SHELL STEP_SHELL LINE: write a one-step workflow into
# fixture/DIR whose step runs LINE. An empty WORKFLOW_SHELL leaves out defaults.run.shell,
# and an empty STEP_SHELL the step's shell.
fixture_workflow() {
  mkdir -p "fixture/$1"
  {
    printf 'on: push\n'
    if [ -n "$2" ]; then
      printf 'defaults:\n  run:\n    shell: %s\n' "$2"
    fi
    printf 'jobs:\n  test:\n    runs-on: ubuntu-latest\n    steps:\n      - name: step\n'
    if [ -n "$3" ]; then
      printf '        shell: %s\n' "$3"
    fi
    printf '        run: |\n          list="$1"\n          %s\n' "$4"
  } >"fixture/$1/ci.yml"
}

It "quote their variables in this repository"
When call _harness_python "$CHECKER" "$PROJECT_ROOT"
The status should be success
The stdout should equal ""
End

It "flags an unquoted variable"
fixture_action 'printf "%s\n" $list'

When call _harness_python "$CHECKER" fixture
The status should be failure
The stdout should include 'SC2086'
End

It "flags an unquoted integer comparison"
fixture_action 'count=1' '[ $count -eq 1 ]'

When call _harness_python "$CHECKER" fixture
The status should be failure
The stdout should include 'SC2248'
End

It "flags a pattern left unquoted in a prefix strip"
fixture_action 'printf "%s\n" "${list#$1}"'

When call _harness_python "$CHECKER" fixture
The status should be failure
The stdout should include 'SC2295'
End

It "accepts a deliberate split between set -f and set +f"
fixture_action 'set -f' 'set -- $list' 'set +f'

When call _harness_python "$CHECKER" fixture
The status should be success
The stdout should equal ""
End

It "still flags an unquoted prefix pattern inside a deliberate split"
# set -f stops pathname expansion only; ${list#$1} still reads $1 as a pattern.
fixture_action 'set -f' 'printf "%s\n" "${list#$1}"' 'set +f'

When call _harness_python "$CHECKER" fixture
The status should be failure
The stdout should include 'SC2295'
End

It "flags an unquoted variable after set +f has closed the split"
fixture_action 'set -f' 'set +f' 'printf "%s\n" $list'

When call _harness_python "$CHECKER" fixture
The status should be failure
The stdout should include 'SC2086'
End

It "does not treat set -f in a comment as a split"
fixture_action '# set -f would be needed here' 'set -- $list'

When call _harness_python "$CHECKER" fixture
The status should be failure
The stdout should include 'SC2086'
End

It "does not treat a printed set -f as a split"
fixture_action 'printf "%s\n" "done; set -f"' 'set -- $list'

When call _harness_python "$CHECKER" fixture
The status should be failure
The stdout should include 'SC2086'
End

It "accepts a split opened after other commands on the line"
fixture_action '_oi="$IFS"; IFS=","; set -f' 'set -- $list' 'set +f; IFS="$_oi"'

When call _harness_python "$CHECKER" fixture
The status should be success
The stdout should equal ""
End

It "checks a step that runs sh through a shell template"
fixture_action 'printf "%s\n" $list'
sed -E -i.bak 's/shell: sh$/shell: sh -e {0}/' fixture/sample/action.yml

When call _harness_python "$CHECKER" fixture
The status should be failure
The stdout should include 'SC2086'
End

It "skips a step whose shell template is not a shell"
fixture_action 'printf "%s\n" $list'
sed -E -i.bak 's/shell: sh$/shell: node {0}/' fixture/sample/action.yml

When call _harness_python "$CHECKER" fixture
The status should be success
The stdout should equal ""
End

# A workflow step that names no shell runs in bash on a Linux runner.
It "flags an unquoted variable in a workflow step that names no shell"
fixture_workflow .github/workflows "" "" 'printf "%s\n" $list'

When call _harness_python "$CHECKER" fixture
The status should be failure
The stdout should include '.github/workflows/ci.yml:9: SC2086'
End

It "takes a workflow step's shell from the workflow's defaults.run.shell"
fixture_workflow .github/workflows pwsh "" 'printf "%s\n" $list'

When call _harness_python "$CHECKER" fixture
The status should be success
The stdout should equal ""
End

It "takes a workflow step's own shell over the defaults"
fixture_workflow .github/workflows pwsh sh 'printf "%s\n" $list'

When call _harness_python "$CHECKER" fixture
The status should be failure
The stdout should include 'SC2086'
End

# The pre-commit hook's file pattern leaves these out, so this check is their only one.
It "checks the integration test workflows"
fixture_workflow _tests/integration/workflows "" "" 'printf "%s\n" $list'

When call _harness_python "$CHECKER" fixture
The status should be failure
The stdout should include '_tests/integration/workflows/ci.yml:'
The stdout should include 'SC2086'
End

# nick-fields/retry runs its command: with bash unless its with: names another shell.
It "flags an unquoted variable in a script nick-fields/retry runs"
mkdir -p fixture/sample
cat >fixture/sample/action.yml <<'EOF'
name: sample
description: sample
runs:
  using: composite
  steps:
    - name: retried
      uses: nick-fields/retry@ad984534de44a9489a53aefd81eb77f87c70dc60 # v4.0.0
      with:
        timeout_minutes: 5
        command: |
          list="$1"
          printf '%s\n' $list
EOF

When call _harness_python "$CHECKER" fixture
The status should be failure
The stdout should include 'fixture/sample/action.yml:'
The stdout should include 'SC2086'
End
End
