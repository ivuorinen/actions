#!/usr/bin/env shellspec
# Behavior-level tests for go-build's dependency steps.
#
# `go mod verify` skips modules missing from the cache, so it can pass after a failed
# `go mod download`. The download has to decide its own step's result.

Describe "go-build (behavior)"
ACTION_DIR="${PROJECT_ROOT}/go-build"

before() {
  shellspec_setup_test_env "go-build-behavior-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "go-build-behavior-$$"
  harness_reset
}
AfterEach 'after'

Describe "Download Dependencies"
It "fails when go mod download fails, even if go mod verify would pass"
mock_command go "mod download" "" 1
mock_command go "mod verify" "" 0

When call run_retry_step "${ACTION_DIR}" "Download Dependencies"
The status should be failure
End

It "succeeds when go mod download succeeds"
mock_command go "mod download" "" 0

When call run_retry_step "${ACTION_DIR}" "Download Dependencies"
The status should be success
End
End

Describe "Verify Dependencies"
It "fails when go mod verify fails"
mock_command go "mod verify" "module changed" 1

When call run_retry_step "${ACTION_DIR}" "Verify Dependencies"
The status should be failure
The output should equal "module changed"
End

It "succeeds when go mod verify succeeds"
mock_command go "mod verify" "all modules verified" 0

When call run_retry_step "${ACTION_DIR}" "Verify Dependencies"
The status should be success
The output should equal "all modules verified"
End
End
End
