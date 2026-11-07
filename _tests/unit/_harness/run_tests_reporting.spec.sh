#!/usr/bin/env shellspec
# The runner's integration summary must not report a skipped workflow as a run.

Describe "run-tests.sh integration reporting"

# Reports go to a private directory so the nested runner never touches the
# reports of the run that is executing this spec.
before() {
  REPORTS_TMP="$(mktemp -d)"
  export TEST_REPORTS_DIR="$REPORTS_TMP"
}
BeforeEach 'before'

after() {
  rm -rf "$REPORTS_TMP"
  unset TEST_REPORTS_DIR
}
AfterEach 'after'

run_integration() {
  bash "${PROJECT_ROOT}/_tests/run-tests.sh" -t integration "$@" 2>&1
}

act_installed() {
  command -v act >/dev/null 2>&1
}

It "counts an action without a workflow as skipped, not run"
When call run_integration docker-build
The status should be success
The output should include "Integration Tests Run:       0"
The output should include "Integration Skipped:         1"
The output should include "Skipped: 1 actions"
End

It "counts a workflow as skipped, not run, when act is not installed"
Skip if "act is installed, the workflow would really run" act_installed
When call run_integration npm-publish
The status should be success
The output should include "Skipping integration test for npm-publish (act not available)"
The output should include "Integration Tests Run:       0"
The output should include "Integration Skipped:         1"
End

It "ignores reports left behind by an earlier run"
mkdir -p "${REPORTS_TMP}/integration"
printf 'stale\n' >"${REPORTS_TMP}/integration/stale-a.txt"
printf 'stale\n' >"${REPORTS_TMP}/integration/stale-b.txt"
When call run_integration docker-build
The status should be success
The output should include "Integration Tests Run:       0"
The output should not include "Integration Tests Run:       2"
End
End
