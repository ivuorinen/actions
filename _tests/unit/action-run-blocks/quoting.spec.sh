#!/usr/bin/env shellspec
# Static check across every composite action: a run: block quotes its variables,
# unless it is a deliberate split between `set -f` and `set +f`.

Describe "composite action run: blocks"
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
End
