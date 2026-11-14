#!/usr/bin/env shellspec
# Behavior tests for csharp-build: the retried dependency restore, and how the
# project input reaches dotnet.
#
# `dotnet` is in the harness's BLOCKED_COMMANDS, so a call whose arguments match
# no mock fails: the mocks below are the assertion on what dotnet receives.

Describe "csharp-build (behavior)"
ACTION_DIR="${PROJECT_ROOT}/csharp-build"
ACTION_FILE="${ACTION_DIR}/action.yml"

before() {
  shellspec_setup_test_env "csharp-build-behavior-$$"
  harness_reset
  printf '<Project><PackageReference Include="xunit" /></Project>\n' >Tests.csproj
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

It "restores the given project"
export INPUT_PROJECT="src/App.sln"
mock_command dotnet "restore src/App.sln --verbosity normal" ""

When call run_retry_step "${ACTION_DIR}" "Restore Dependencies"
The status should be success
End

It "restores the repository root when no project is given"
mock_command dotnet "restore --verbosity normal" ""

When call run_retry_step "${ACTION_DIR}" "Restore Dependencies"
The status should be success
End

# The harness runs the command in the shell the step names. On Windows, retry's default
# is PowerShell, which cannot read the expansion, so the step has to name bash.
It "runs the restore in bash with the project in its environment"
When call yq -r '.runs.steps[] | select(.name == "Restore Dependencies") | .with.shell + " " + .env.PROJECT' "$ACTION_FILE"
The stdout should equal 'bash ${{ inputs.project }}'
End
End

Describe "project selection"
It "builds the given project"
export INPUT_PROJECT="src/App.sln"
mock_command dotnet "build src/App.sln --configuration Release --no-restore --verbosity normal" ""

When call run_step "${ACTION_DIR}" "build"
The status should be success
The stdout should include "Build completed successfully"
End

It "builds the repository root when no project is given"
mock_command dotnet "build --configuration Release --no-restore --verbosity normal" ""

When call run_step "${ACTION_DIR}" "build"
The status should be success
The stdout should include "Build completed successfully"
End

It "tests the given project"
export INPUT_PROJECT="src/App.sln"
mock_command dotnet "test src/App.sln --configuration Release --no-build --collect:*" ""

When call run_step "${ACTION_DIR}" "test"
The status should be success
The stdout should include "Tests completed successfully"
End

It "tests the repository root when no project is given"
mock_command dotnet "test --configuration Release --no-build --collect:*" ""

When call run_step "${ACTION_DIR}" "test"
The status should be success
The stdout should include "Tests completed successfully"
End
End
End
