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

Describe "main-package discovery"
# Discovery must handle directory and file names containing spaces or a leading dash.
set_destination() { export INPUT_DESTINATION="${PWD}/out"; }
Before 'set_destination'

It "builds a main package in a directory containing a space"
mkdir -p "my app"
printf 'package main\n\nfunc main() {}\n' >"my app/main.go"
mock_command go "build*" "" 0

When call run_step "${ACTION_DIR}" "build"
The status should be success
The stdout should include "Building package in ./my app..."
The stdout should include "Build completed successfully"
Assert expect_output status success
End

It "builds a main package whose directory starts with a dash"
mkdir -p -- "-cmd"
printf 'package main\n\nfunc main() {}\n' >"-cmd/main.go"
mock_command go "build*" "" 0

When call run_step "${ACTION_DIR}" "build"
The status should be success
The stdout should include "Building package in ./-cmd..."
Assert expect_output status success
End
End
End
