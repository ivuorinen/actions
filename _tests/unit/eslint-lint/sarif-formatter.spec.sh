#!/usr/bin/env shellspec
# The default SARIF report needs a formatter package. A repository with its own ESLint but no
# formatter must still get a report, so the action installs a pinned copy into a temporary prefix
# and hands ESLint its entry file. Mocks match exact arguments: any other call exits 127 and
# fails the example, which is how "installs nothing" is asserted.

Describe "eslint-lint SARIF formatter"
ACTION_DIR="${PROJECT_ROOT}/eslint-lint"

before() {
  shellspec_setup_test_env "eslint-lint-sarif-$$"
  harness_reset
  export INPUT_MODE="check"
  export INPUT_REPORT_FORMAT="sarif"
  export PACKAGE_MANAGER="npm"
  export RUNNER_TEMP="$PWD"
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "eslint-lint-sarif-$$"
  harness_reset
}
AfterEach 'after'

pinned_formatter_version() {
  grep -A1 -F '# renovate: datasource=npm depName=@microsoft/eslint-formatter-sarif' "${ACTION_DIR}/action.yml" |
    sed -E -n "s/^ *SARIF_FORMATTER_VERSION: '([^']+)'.*/\\1/p"
}

It "keeps the pin where Renovate tracks it"
When call pinned_formatter_version
The output should match pattern "[0-9]*.[0-9]*.[0-9]*"
End

It "uses the repository's formatter by name when it has one"
mock_command node "-e *" ""
mock_command npx "eslint . --ext * --max-warnings * --format @microsoft/eslint-formatter-sarif --output-file eslint-results.sarif" ""
When call run_step "${ACTION_DIR}" "check"
The status should be success
The stdout should include "ESLint check completed"
End

It "installs the pinned formatter outside the repository and passes its entry file"
version=$(pinned_formatter_version)
mock_command node "-e *" "" 1
mock_command npm "install --prefix ${RUNNER_TEMP}/eslint-sarif-formatter.* --no-package-lock --no-audit --no-fund --ignore-scripts @microsoft/eslint-formatter-sarif@${version}" ""
mock_command node "-p *" "/tmp/prefix/node_modules/@microsoft/eslint-formatter-sarif/sarif.js"
mock_command npx "eslint . --ext * --max-warnings * --format /tmp/prefix/node_modules/@microsoft/eslint-formatter-sarif/sarif.js --output-file eslint-results.sarif" ""
When call run_step "${ACTION_DIR}" "check"
The status should be success
The stdout should include "ESLint check completed"
End

It "does not install anything for a non-SARIF report"
export INPUT_REPORT_FORMAT="json"
mock_command npx "eslint . --ext * --max-warnings * --format json" ""
When call run_step "${ACTION_DIR}" "check"
The status should be success
The stdout should include "ESLint check completed"
End
End
