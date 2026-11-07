#!/usr/bin/env shellspec
# An unusable retry count must fail the install step, never leave it passing without installing.

Describe "go-lint install step (behavior)"
ACTION_DIR="${PROJECT_ROOT}/go-lint"

before() {
  shellspec_setup_test_env "go-lint-install-$$"
  harness_reset
  export INPUT_GOLANGCI_LINT_VERSION="latest"
  mock_command go "*" "GO-INSTALL-RAN"
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "go-lint-install-$$"
  harness_reset
  unset INPUT_GOLANGCI_LINT_VERSION INPUT_MAX_RETRIES
}
AfterEach 'after'

It "installs on the first attempt with a usable retry count"
export INPUT_MAX_RETRIES="3"
When call run_step "${ACTION_DIR}" "install-golangci-lint"
The status should be success
The output should include "GO-INSTALL-RAN"
End

It "fails without installing when the retry count is blank"
export INPUT_MAX_RETRIES=""
When call run_step "${ACTION_DIR}" "install-golangci-lint"
The status should be failure
The output should include "::error::Failed to install golangci-lint"
The output should not include "GO-INSTALL-RAN"
The stderr should be present
End
End
