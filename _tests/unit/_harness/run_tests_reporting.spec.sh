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

It "counts an action without a workflow as skipped, not run"
When call run_integration docker-build
The status should be success
The output should include "Integration Tests Run:       0"
The output should include "Integration Skipped:         1"
The output should include "Skipped: 1 actions"
End

# ACT_BIN names a command that does not exist, so this runs where act is installed too.
It "counts a workflow as skipped, not run, when act is not installed"
export ACT_BIN="no-such-act-binary"
When call run_integration npm-publish
The status should be success
The output should include "Skipping integration test for npm-publish (act not available)"
The output should include "Integration Tests Run:       0"
The output should include "Integration Skipped:         1"
End

# A stub act exits with the given status, standing in for a workflow that passes or fails.
stub_act() {
  mkdir -p "${REPORTS_TMP}/bin"
  printf '#!/bin/sh\nexit %s\n' "$1" >"${REPORTS_TMP}/bin/act"
  chmod +x "${REPORTS_TMP}/bin/act"
  export ACT_BIN="${REPORTS_TMP}/bin/act"
}

Describe "a workflow act runs"
Parameters
"passes" 0 success
"fails" 1 failure
End

It "counts a workflow that $1 as one run"
stub_act "$2"
When call run_integration npm-publish
The status should be "$3"
The output should include "Integration Tests Run:       1"
The output should include "Integration Skipped:         0"
End
End

Describe "the JSON report"
json_integration_tests() { jq -r '.results.integration_tests' "${REPORTS_TMP}/test-results.json"; }
json_integration_skipped() { jq -r '.results.integration_skipped' "${REPORTS_TMP}/test-results.json"; }

# The JSON format prints no console summary, so these read the counts from the report.
It "counts a failed workflow as a run"
stub_act 1
When call run_integration npm-publish --format json
The status should be failure
The output should include "JSON report generated"
The result of function json_integration_tests should equal "1"
End

It "counts an action without a workflow as skipped"
When call run_integration docker-build --format json
The status should be success
The output should include "JSON report generated"
The result of function json_integration_skipped should equal "1"
The result of function json_integration_tests should equal "0"
End
End

# The link stands in for TEST_REPORTS_DIR=_tests. Should the guard ever fail, rm -rf
# removes only the link, never the specs it points at.
It "refuses to clean a reports directory that leads to the test sources"
ln -s "${PROJECT_ROOT}/_tests/unit" "${REPORTS_TMP}/unit"
When call run_integration docker-build
The status should be failure
The output should include "refusing to clean it"
The path "${REPORTS_TMP}/unit" should be symlink
The path "${PROJECT_ROOT}/_tests/unit/_harness/run_tests_reporting.spec.sh" should be exist
End

# Here the link leads into the sources rather than to their root, as a reports directory
# placed inside _tests/unit would.
It "refuses to clean a reports directory that sits inside the test sources"
ln -s "${PROJECT_ROOT}/_tests/unit/_harness" "${REPORTS_TMP}/integration"
When call run_integration docker-build
The status should be failure
The output should include "refusing to clean it"
The path "${REPORTS_TMP}/integration" should be symlink
The path "${PROJECT_ROOT}/_tests/unit/_harness/run_tests_reporting.spec.sh" should be exist
End

It "removes a plain file where a reports directory belongs, instead of stopping"
printf 'not a directory\n' >"${REPORTS_TMP}/integration"
When call run_integration docker-build
The status should be success
The output should include "Integration Skipped:         1"
The path "${REPORTS_TMP}/integration" should be directory
End

It "ignores reports left behind by an earlier run"
mkdir -p "${REPORTS_TMP}/integration"
printf 'stale\n' >"${REPORTS_TMP}/integration/stale-a.txt"
printf 'stale\n' >"${REPORTS_TMP}/integration/stale-b.txt"
When call run_integration docker-build
The status should be success
The output should include "Integration Tests Run:       0"
The output should not include "Integration Tests Run:       2"
The path "${REPORTS_TMP}/integration/stale-a.txt" should not be exist
The path "${REPORTS_TMP}/integration/stale-b.txt" should not be exist
End
End
