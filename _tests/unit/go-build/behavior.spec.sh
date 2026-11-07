#!/usr/bin/env shellspec
# Behavior test for go-build: main-package discovery must handle
# repository directory and file names containing spaces or a leading dash.

Describe "go-build build step"
ACTION_DIR="${PROJECT_ROOT}/go-build"

before() {
  shellspec_setup_test_env "go-build-behavior-$$"
  harness_reset
  export INPUT_DESTINATION="${PWD}/out"
}
BeforeEach 'before'

after() {
  unset INPUT_DESTINATION
  shellspec_cleanup_test_env "go-build-behavior-$$"
  harness_reset
}
AfterEach 'after'

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
