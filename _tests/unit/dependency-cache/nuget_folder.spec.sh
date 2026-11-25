#!/usr/bin/env shellspec
# The csharp actions cache the folder NuGet reports, so a caller's NUGET_PACKAGES is the folder
# cached, in the runner's own path form.

Describe "Locate NuGet Packages"
before() {
  shellspec_setup_test_env "nuget-folder-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "nuget-folder-$$"
  harness_reset
}
AfterEach 'after'

Parameters
csharp-build
csharp-lint-check
csharp-publish
End

It "gives $1 the folder NuGet reports"
mock_command dotnet "nuget locals global-packages --list" "global-packages: /custom/nuget/packages/"

When call run_step "${PROJECT_ROOT}/$1" "nuget-folder"
The status should be success
Assert expect_output path "/custom/nuget/packages/"
End
End
