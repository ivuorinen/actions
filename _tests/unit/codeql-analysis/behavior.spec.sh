#!/usr/bin/env shellspec
# Behavior-level tests for codeql-analysis's `checkout-safety` and `output-path` steps.
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

It "runs on every trigger, because no condition can skip it"
When call yq -r '.runs.steps[] | select(.id == "checkout-safety") | has("if")' "${ACTION_DIR}/action.yml"
The stdout should equal "false"
End
End

Describe "sarif-file output"
It "reads the output github/codeql-action/analyze sets"
When call grep -qF 'value: ${{ steps.analysis.outputs.sarif-output }}' "${ACTION_DIR}/action.yml"
The status should be success
End
End

# The analysis deletes the output directory, so a symlink the checkout commits on that path
# would redirect the deletion. The directory "shared" stands in for a path outside the workspace.
Describe "output-path"
before_output() {
  export GITHUB_WORKSPACE="$PWD"
  mkdir shared
}
BeforeEach 'before_output'

It "refuses an output path through a symlinked directory"
ln -s "$PWD/shared" reports
export INPUT_OUTPUT="reports/sarif"
When call run_step "${ACTION_DIR}" "output-path"
The status should be failure
The stdout should include "::error::"
The stdout should include "reports is one"
End

It "refuses it after a leading ./"
ln -s "$PWD/shared" reports
export INPUT_OUTPUT="./reports/sarif"
When call run_step "${ACTION_DIR}" "output-path"
The status should be failure
The stdout should include "reports is one"
End

It "refuses an output directory that is itself a symlink"
ln -s "$PWD/shared" codeql-results
export INPUT_OUTPUT="codeql-results"
When call run_step "${ACTION_DIR}" "output-path"
The status should be failure
The stdout should include "codeql-results is one"
End

It "accepts a nested path of real directories"
mkdir -p reports/sarif
export INPUT_OUTPUT="reports/sarif"
When call run_step "${ACTION_DIR}" "output-path"
The status should be success
End

It "accepts a path that does not exist yet"
export INPUT_OUTPUT="codeql-results"
When call run_step "${ACTION_DIR}" "output-path"
The status should be success
End

It "runs after the checkout that could bring the symlink in, and before the analysis"
checkout_line=$(grep -n '^    - name: Checkout repository' "${ACTION_DIR}/action.yml" | cut -d: -f1)
check_line=$(grep -n '^    - name: Check output path' "${ACTION_DIR}/action.yml" | cut -d: -f1)
analysis_line=$(grep -n '^    - name: Perform CodeQL Analysis' "${ACTION_DIR}/action.yml" | cut -d: -f1)
When call test "$checkout_line" -lt "$check_line" -a "$check_line" -lt "$analysis_line"
The status should be success
End

It "runs on every trigger, because no condition can skip it"
When call yq -r '.runs.steps[] | select(.id == "output-path") | has("if")' "${ACTION_DIR}/action.yml"
The stdout should equal "false"
End
End
End
