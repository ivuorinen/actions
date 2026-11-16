#!/usr/bin/env shellspec
# The check step reads its counts from the SARIF report. The report here is the shape
# @microsoft/eslint-formatter-sarif writes: one artifact per linted file, and a result only
# for each finding. A fake ESLint stands in for the command the ensure step chose: it logs
# its arguments, writes FAKE_REPORT to the --output-file when one is set, and exits with
# FAKE_ESLINT_EXIT.

Describe "eslint-lint check outputs"
ACTION_DIR="${PROJECT_ROOT}/eslint-lint"

# A clean file and a file with one error.
REPORT='{"runs": [{"artifacts": [{"location": {"uri": "file:///w/clean.js"}}, {"location": {"uri": "file:///w/bad.js"}}], "results": [{"level": "error", "ruleId": "no-unused-vars", "locations": [{"physicalLocation": {"artifactLocation": {"uri": "file:///w/bad.js", "index": 1}}}]}]}]}'

before() {
  shellspec_setup_test_env "eslint-lint-check-outputs-$$"
  harness_reset
  FAKE_ESLINT="${SHELLSPEC_TEST_TEMP_DIR}/fake-eslint"
  export ESLINT_ARGS="${SHELLSPEC_TEST_TEMP_DIR}/eslint-args"
  cat >"$FAKE_ESLINT" <<'FAKE'
#!/bin/sh
printf '%s\n' "$*" >"$ESLINT_ARGS"
if [ -n "${FAKE_REPORT:-}" ]; then
  while [ "$#" -gt 0 ]; do
    if [ "$1" = "--output-file" ]; then printf '%s\n' "$FAKE_REPORT" >"$2"; fi
    shift
  done
fi
exit "${FAKE_ESLINT_EXIT:-0}"
FAKE
  chmod +x "$FAKE_ESLINT"
  export HARNESS_STEP_OUTPUTS="{\"ensure-eslint\":{\"outputs\":{\"command\":\"${FAKE_ESLINT}\",\"formatter\":\"/tmp/f/sarif.js\"}}}"
  export INPUT_FILE_EXTENSIONS=".js" INPUT_CONFIG_FILE=".eslintrc" INPUT_CACHE="false"
  export INPUT_MAX_WARNINGS="0" INPUT_REPORT_FORMAT="sarif" INPUT_FAIL_ON_ERROR="true"
}
BeforeEach 'before'

after() {
  unset FAKE_REPORT FAKE_ESLINT_EXIT ESLINT_ARGS
  shellspec_cleanup_test_env "eslint-lint-check-outputs-$$"
  harness_reset
}
AfterEach 'after'

It "counts every linted file, with or without findings"
export FAKE_REPORT="$REPORT"
When call run_step "${ACTION_DIR}" "check"
The status should be success
The stdout should include "ESLint check completed"
The contents of file "$ESLINT_ARGS" should include "--format /tmp/f/sarif.js --output-file eslint-results.sarif"
Assert expect_output files_checked 2
Assert expect_output error_count 1
Assert expect_output warning_count 0
End

It "counts no files when ESLint wrote no report"
export INPUT_REPORT_FORMAT="stylish"
When call run_step "${ACTION_DIR}" "check"
The status should be success
The stdout should include "ESLint check completed"
Assert expect_output files_checked 0
End

# A report committed to the checkout is not this run's result: when ESLint fails before
# writing one, the counts and the upload must not read the old file.
It "ignores a report left in the checkout when ESLint writes none"
printf '%s\n' "$REPORT" >eslint-results.sarif
export FAKE_ESLINT_EXIT=2 INPUT_FAIL_ON_ERROR="false"
When call run_step "${ACTION_DIR}" "check"
The status should be success
The stdout should include "ESLint check completed"
The path "eslint-results.sarif" should not be exist
Assert expect_output files_checked 0
Assert expect_output error_count 0
Assert expect_output sarif_file ""
Assert expect_output status failure
End

It "leaves eslint-results.sarif alone for another report format"
printf '%s\n' "$REPORT" >eslint-results.sarif
export INPUT_REPORT_FORMAT="stylish"
When call run_step "${ACTION_DIR}" "check"
The status should be success
The stdout should include "ESLint check completed"
The path "eslint-results.sarif" should be file
Assert expect_output files_checked 0
End

It "fails instead of deleting a directory named like the report"
mkdir eslint-results.sarif
: >eslint-results.sarif/keep
When call run_step "${ACTION_DIR}" "check"
The status should be failure
The stdout should include "Running ESLint check mode"
The stderr should include "eslint-results.sarif"
The path "eslint-results.sarif/keep" should be file
End

# The harness does not evaluate step conditions, so this reads the upload's.
It "uploads only a report the check step wrote"
When call yq -r '.runs.steps[] | select(.name == "Upload SARIF Report") | .if' "${ACTION_DIR}/action.yml"
The output should include "always()"
The output should include "steps.check.outputs.sarif_file != ''"
End

# The harness does not evaluate action outputs, so this reads the mapping.
It "reports 0 when the check step did not run, as in fix mode"
When call yq -r '.outputs."files-checked".value' "${ACTION_DIR}/action.yml"
The output should equal "\${{ steps.check.outputs.files_checked || '0' }}"
End
End
