#!/usr/bin/env shellspec
# go-lint installs golangci-lint at a pinned v2 version, and the flags it runs it with exist in
# v2. Mocks match exact arguments, so a wrong module path or a removed flag exits 127 and fails
# the example.

Describe "go-lint tool pins"
ACTION_DIR="${PROJECT_ROOT}/go-lint"
MODULE="github.com/golangci/golangci-lint/v2/cmd/golangci-lint"

before() {
  shellspec_setup_test_env "go-lint-pins-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "go-lint-pins-$$"
  harness_reset
}
AfterEach 'after'

It "sets up the pinned Go unless the caller names one"
The contents of file "${ACTION_DIR}/action.yml" should include 'go-version: ${{ inputs.go-version || env.DEFAULT_GO_VERSION }}'
End

Describe "Resolve golangci-lint Version"
It "resolves to the pin when the caller names no version"
When call run_step "${ACTION_DIR}" "golangci-version"
The status should be success
Assert expect_output version "$(pinned_version go-lint DEFAULT_GOLANGCI_LINT_VERSION)"
End

Describe "when the caller names a version"
Parameters
"latest" "latest"
"v2.1.0" "v2.1.0"
"2.1.0" "v2.1.0"
"v2.1.0-rc.1" "v2.1.0-rc.1"
"2.1.0+build" "v2.1.0+build"
"2.1" "v2.1"
End

It "resolves $1 to $2"
export INPUT_GOLANGCI_LINT_VERSION="$1"
When call run_step "${ACTION_DIR}" "golangci-version"
The status should be success
Assert expect_output version "$2"
End
End
End

Describe "Install golangci-lint"
before_install() {
  export INPUT_MAX_RETRIES="1"
  export HARNESS_STEPS='{"golangci-version":{"outputs":{"version":"v2.1.0"}}}'
}
BeforeEach 'before_install'

It "installs the resolved version from the v2 module"
mock_command go "install ${MODULE}@v2.1.0" ""
When call run_step "${ACTION_DIR}" "install"
The status should be success
The stdout should include "Installation attempt 1 of 1"
End

It "fails with an error when it cannot"
mock_command go "install *" "" 1
When call run_step "${ACTION_DIR}" "install"
The status should be failure
The stdout should include "::error::Failed to install golangci-lint"
End
End

Describe "Run golangci-lint"
before_lint() {
  export INPUT_WORKING_DIRECTORY="." INPUT_CONFIG_FILE=".golangci.yml" INPUT_TIMEOUT="5m"
  export INPUT_FAIL_ON_ERROR="true" INPUT_ONLY_NEW_ISSUES="false" INPUT_DISABLE_ALL="false"
  export INPUT_ENABLE_LINTERS="" INPUT_DISABLE_LINTERS="" INPUT_REPORT_FORMAT="sarif" INPUT_CACHE="true"
}
BeforeEach 'before_lint'

BASE="run --config .golangci.yml --timeout 5m"

It "passes only flags v2 has when caching is on"
mock_command golangci-lint "${BASE} --output.sarif.path=reports/golangci-lint.sarif ./..." "{}"
When call run_step "${ACTION_DIR}" "lint"
The status should be success
The stdout should include "Running golangci-lint"
End

It "passes only flags v2 has when caching is off"
export INPUT_CACHE="false"
mock_command golangci-lint "${BASE} --output.sarif.path=reports/golangci-lint.sarif ./..." "{}"
When call run_step "${ACTION_DIR}" "lint"
The status should be success
The stdout should include "Running golangci-lint"
End

It "asks v2 for no default linters when disable-all is set"
export INPUT_DISABLE_ALL="true" INPUT_ENABLE_LINTERS="govet"
mock_command golangci-lint "${BASE} --default=none --enable=govet --output.sarif.path=reports/golangci-lint.sarif ./..." "{}"
When call run_step "${ACTION_DIR}" "lint"
The status should be success
The stdout should include "Running golangci-lint"
End

Describe "report formats"
Parameters
"json" "json"
"sarif" "sarif"
"github-actions" "text"
End

It "writes $1 through --output.$2.path"
export INPUT_REPORT_FORMAT="$1"
mock_command golangci-lint "${BASE} --output.$2.path=reports/golangci-lint.$1 ./..." "{}"
When call run_step "${ACTION_DIR}" "lint"
The status should be success
The stdout should include "Running golangci-lint"
Assert expect_output sarif_file "reports/golangci-lint.$1"
End
End

# GitHub rejects $GITHUB_OUTPUT as a whole when any line in it is not key=value.
only_key_value_lines() {
  ! grep -qv '=' "$GITHUB_OUTPUT"
}

# Report bodies in the form golangci-lint v2.15.0 writes them. A text report has source lines
# under each issue, and a compile error's message spans two lines but is one issue.
report_fixture() {
  case "$1" in
  sarif)
    printf '%s\n' '{"runs":[{"results":[{"level":"error"},{"level": "error"},{"level":"warning"}]}]}'
    ;;
  json)
    printf '%s\n' '{"Issues":[{"FromLinter":"unused"},{"FromLinter":"ineffassign"},{"FromLinter":"govet"}]}'
    ;;
  github-actions)
    printf '%s\n' 'main.go:5:6: func unusedHelper is unused (unused)' 'func unusedHelper() int {' '     ^' \
      'main.go:1: : # example.com/x' './main.go:10:2: declared and not used: x (typecheck)' 'package main'
    ;;
  esac
}

Describe "when golangci-lint reports findings and fail-on-error is off"
before_findings() {
  export INPUT_FAIL_ON_ERROR="false"
}
BeforeEach 'before_findings'

Parameters
"sarif" "sarif" "2"
"json" "json" "3"
"github-actions" "text" "2"
End

# golangci-lint writes the report itself and a mock can't, so the report is in place first. The
# mock prints statistics to stdout as v2 does; a redirect to the report would overwrite it.
It "counts the $1 report and keeps statistics out of it"
export INPUT_REPORT_FORMAT="$1"
mkdir -p reports
report_fixture "$1" >"reports/golangci-lint.$1"
mock_command golangci-lint "${BASE} --output.$2.path=reports/golangci-lint.$1 ./..." "3 issues:" 1
When call run_step "${ACTION_DIR}" "lint"
The status should be success
The stdout should include "3 issues:"
The contents of file "reports/golangci-lint.$1" should not include "issues:"
Assert expect_output error_count "$3"
Assert only_key_value_lines
End
End

It "fails without a count when golangci-lint could not run"
mock_command golangci-lint "${BASE} --output.sarif.path=reports/golangci-lint.sarif ./..." "" 3
When call run_step "${ACTION_DIR}" "lint"
The status should be failure
The stdout should include "::error::golangci-lint exited with 3, 0 issues found"
Assert expect_output error_count "0"
End
End

Describe "Prepare Configuration"
It "writes a default config in the v2 format"
export INPUT_WORKING_DIRECTORY="." INPUT_CONFIG_FILE=".golangci.yml" INPUT_TIMEOUT="5m"
When call run_step "${ACTION_DIR}" "config"
The status should be success
The stdout should include "Creating default"
The contents of file ".golangci.yml" should include 'version: "2"'
The contents of file ".golangci.yml" should include "default: all"
The contents of file ".golangci.yml" should include "timeout: 5m"
The contents of file ".golangci.yml" should not include "enable-all"
The contents of file ".golangci.yml" should not include "linters-settings"
The contents of file ".golangci.yml" should not include "deadline"
End
End
End
