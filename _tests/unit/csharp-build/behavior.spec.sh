#!/usr/bin/env shellspec
# Behavior test for csharp-build: test-project detection must handle
# repository filenames containing spaces or a leading dash.

Describe "csharp-build test step"
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

It "detects a test project whose path contains a space"
mkdir -p "my tests"
printf '<PackageReference Include="xunit" />\n' >"my tests/my tests.csproj"
mock_command dotnet "test*" "" 0

When call run_step "${ACTION_DIR}" "test"
The status should be success
The stdout should include "Tests completed successfully"
Assert expect_output status success
End

It "detects a test project whose filename starts with a dash"
printf '<PackageReference Include="xunit" />\n' >-tests.csproj
mock_command dotnet "test*" "" 0

When call run_step "${ACTION_DIR}" "test"
The status should be success
The stdout should include "Tests completed successfully"
Assert expect_output status success
End

It "skips tests when no test project exists"
mkdir -p "my app"
printf '<Project />\n' >"my app/my app.csproj"

When call run_step "${ACTION_DIR}" "test"
The status should be success
The stdout should include "No test projects found"
Assert expect_output status skipped
End
End
