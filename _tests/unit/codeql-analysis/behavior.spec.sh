#!/usr/bin/env shellspec
# Behavior-level tests for codeql-analysis's `checkout-safety` step.
#
# Autobuild runs the checked-out code with the job's token and secrets. On
# pull_request_target and workflow_run those belong to the base repository, so a
# caller-chosen ref has to fail before anything is checked out. The checkout and
# CodeQL steps are `uses:` steps the harness does not run, so their order and the
# sarif-file mapping are asserted against action.yml.

Describe "codeql-analysis (behavior)"
ACTION_DIR="${PROJECT_ROOT}/codeql-analysis"

before() {
  shellspec_setup_test_env "codeql-analysis-behavior-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "codeql-analysis-behavior-$$"
  harness_reset
}
AfterEach 'after'

Describe "checkout-safety"
Describe "on a trigger that runs with base repository privileges"
Parameters
"pull_request_target"
"workflow_run"
End

It "refuses a custom checkout-ref on $1"
export GITHUB_EVENT_NAME="$1"
export INPUT_CHECKOUT_REF="feature/x"

When call run_step "${ACTION_DIR}" "checkout-safety"
The status should be failure
The stdout should include "::error::"
The stdout should include "$1"
End

It "allows the default checkout on $1"
export GITHUB_EVENT_NAME="$1"
export INPUT_CHECKOUT_REF=""

When call run_step "${ACTION_DIR}" "checkout-safety"
The status should be success
End
End

Describe "on any other trigger"
Parameters
"pull_request"
"push"
"schedule"
End

It "allows a custom checkout-ref on $1"
export GITHUB_EVENT_NAME="$1"
export INPUT_CHECKOUT_REF="feature/x"

When call run_step "${ACTION_DIR}" "checkout-safety"
The status should be success
End
End

# run_step looks up steps by id regardless of position, so the harness cannot
# see a guard that moved below the code it protects.
It "runs before the repository is checked out"
guard_line=$(grep -n '^    - name: Validate checkout safety' "${ACTION_DIR}/action.yml" | cut -d: -f1)
checkout_line=$(grep -n '^    - name: Checkout repository' "${ACTION_DIR}/action.yml" | cut -d: -f1)
When call test "$guard_line" -lt "$checkout_line"
The status should be success
End
End

Describe "sarif-file output"
It "reads the output github/codeql-action/analyze sets"
When call grep -qF 'value: ${{ steps.analysis.outputs.sarif-output }}' "${ACTION_DIR}/action.yml"
The status should be success
End
End
End
