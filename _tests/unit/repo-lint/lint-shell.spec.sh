#!/usr/bin/env shellspec
# Unit tests for `make lint-shell`, which test-actions' shell scan runs too.
#
# It checks every shell script outside .venv and .worktrees, the plain scripts under _tests
# included, and fails on a finding. A ShellSpec spec file is ShellSpec's DSL, which shellcheck
# misreads, so it is left to ShellSpec.

Describe "make lint-shell"
FIX_ROOT="${SHELLSPEC_TMPBASE}/lint-shell"

# lint_tree: runs the repository's lint-shell target over the fixture tree.
lint_tree() {
  make -s -f "${PROJECT_ROOT}/Makefile" -C "$FIX_ROOT" lint-shell
}

setup() {
  rm -rf "$FIX_ROOT"
  mkdir -p "$FIX_ROOT/_tests/framework" "$FIX_ROOT/_tests/unit/example"
  printf '%s\n' '#!/usr/bin/env bash' 'greet() { printf "%s\n" "$1"; }' >"$FIX_ROOT/_tests/framework/utils.sh"
  # It and When lines read as commands to shellcheck (SC2286, SC2288).
  printf '%s\n' '#!/usr/bin/env shellspec' 'Describe "x"' 'It "says hi."' "When call echo 'hi \$x'" \
    'The output should equal "hi $x"' 'End' 'End' >"$FIX_ROOT/_tests/unit/example/x.spec.sh"
}
BeforeEach 'setup'

It "passes clean scripts and leaves ShellSpec spec files to ShellSpec"
When call lint_tree
The status should be success
The output should include "Shell linting passed"
End

It "fails on a finding in a plain script under _tests"
printf '%s\n' 'shout() { echo $1; }' >>"$FIX_ROOT/_tests/framework/utils.sh"
When call lint_tree
The status should be failure
The output should include "SC2086"
The output should include "Shell linting issues found"
The error should include "lint-shell"
End

It "is the check test-actions' shell scan runs"
The contents of file "${PROJECT_ROOT}/.github/workflows/test-actions.yml" should include "make lint-shell"
The contents of file "${PROJECT_ROOT}/.github/workflows/test-actions.yml" should not include "-exec shellcheck"
End
End
