#!/usr/bin/env shellspec
# Behavior-level tests for csharp-build's retried dependency restore.

Describe "csharp-build (behavior)"
ACTION_DIR="${PROJECT_ROOT}/csharp-build"

before() {
  shellspec_setup_test_env "csharp-build-behavior-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "csharp-build-behavior-$$"
  harness_reset
}
AfterEach 'after'

Describe "Restore Dependencies"
It "fails when dotnet restore fails"
mock_command dotnet "restore --verbosity normal" "" 1

When call run_retry_step "${ACTION_DIR}" "Restore Dependencies"
The status should be failure
End

It "succeeds when dotnet restore succeeds"
mock_command dotnet "restore --verbosity normal" "" 0

When call run_retry_step "${ACTION_DIR}" "Restore Dependencies"
The status should be success
End
End
End
