#!/usr/bin/env shellspec
# The check step reads its counts from the SARIF report. The report here is the shape
# @microsoft/eslint-formatter-sarif writes: one artifact per linted file, and a result only
# for each finding. ESLint itself is mocked, so the report is laid out before the step runs.

Describe "eslint-lint check outputs"
ACTION_DIR="${PROJECT_ROOT}/eslint-lint"

before() {
  shellspec_setup_test_env "eslint-lint-check-outputs-$$"
  harness_reset
  export HARNESS_STEP_OUTPUTS='{"ensure-eslint":{"outputs":{"command":"npx --no-install eslint","formatter":"/tmp/f/sarif.js"}}}'
  export INPUT_FILE_EXTENSIONS=".js" INPUT_CONFIG_FILE=".eslintrc" INPUT_CACHE="false"
  export INPUT_MAX_WARNINGS="0" INPUT_REPORT_FORMAT="sarif" INPUT_FAIL_ON_ERROR="true"
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "eslint-lint-check-outputs-$$"
  harness_reset
}
AfterEach 'after'

# A clean file and a file with one error.
write_report() {
  printf '%s\n' '{"runs": [{"artifacts": [{"location": {"uri": "file:///w/clean.js"}}, {"location": {"uri": "file:///w/bad.js"}}], "results": [{"level": "error", "ruleId": "no-unused-vars", "locations": [{"physicalLocation": {"artifactLocation": {"uri": "file:///w/bad.js", "index": 1}}}]}]}]}' >eslint-results.sarif
}

It "counts every linted file, with or without findings"
write_report
mock_command npx "--no-install eslint . --ext .js --max-warnings 0 --format /tmp/f/sarif.js --output-file eslint-results.sarif" ""
When call run_step "${ACTION_DIR}" "check"
The status should be success
The stdout should include "ESLint check completed"
Assert expect_output files_checked 2
Assert expect_output error_count 1
Assert expect_output warning_count 0
End

It "counts no files when ESLint wrote no report"
export INPUT_REPORT_FORMAT="stylish"
mock_command npx "--no-install eslint . --ext .js --max-warnings 0 --format stylish" ""
When call run_step "${ACTION_DIR}" "check"
The status should be success
The stdout should include "ESLint check completed"
Assert expect_output files_checked 0
End

# The harness does not evaluate action outputs, so this reads the mapping.
It "reports 0 when the check step did not run, as in fix mode"
When call yq -r '.outputs."files-checked".value' "${ACTION_DIR}/action.yml"
The output should equal "\${{ steps.check.outputs.files_checked || '0' }}"
End
End
