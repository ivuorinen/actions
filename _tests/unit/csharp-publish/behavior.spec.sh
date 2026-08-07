#!/usr/bin/env shellspec
# Behavior-level tests for csharp-publish's `extract-version` and
# `publish-package` steps.
#
# csharp-publish had validation specs only, so the shell that selects which
# package to publish and gates `dotnet nuget push` never ran in the suite
# (see docs/audit/findings, tests-94a13648).
#
# `dotnet` is not in the harness's BLOCKED_COMMANDS list, but the child PATH is
# restricted to the mock bin dir plus the system dirs, so it does not resolve
# unless mocked — an unmocked call fails rather than reaching a real toolchain.
# `sleep` is mocked in the retry test so the action's 5-second backoff does not
# make the suite wait.

Describe "csharp-publish (behavior)"
ACTION_DIR="${PROJECT_ROOT}/csharp-publish"

before() {
  shellspec_setup_test_env "csharp-publish-behavior-$$"
  harness_reset
  mkdir -p artifacts
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "csharp-publish-behavior-$$"
  harness_reset
}
AfterEach 'after'

Describe "extract-version"
It "extracts the version from a single .nupkg filename"
: >artifacts/Acme.Widgets.1.2.3.nupkg

When call run_step "${ACTION_DIR}" "extract-version"
The status should be success
Assert expect_output version "1.2.3"
Assert expect_output package_file "./artifacts/Acme.Widgets.1.2.3.nupkg"
End

It "keeps the prerelease suffix in the extracted version"
: >artifacts/Acme.Widgets.2.0.0-rc.1.nupkg

When call run_step "${ACTION_DIR}" "extract-version"
The status should be success
Assert expect_output version "2.0.0-rc.1"
End

It "selects the newest package by mtime when several are present"
# The step uses the POSIX `-nt` test rather than GNU `find -printf`. Ordering
# is established explicitly with touch so the assertion does not depend on
# readdir order, which is not guaranteed.
: >artifacts/Acme.Widgets.1.0.0.nupkg
: >artifacts/Acme.Widgets.3.0.0.nupkg
: >artifacts/Acme.Widgets.2.0.0.nupkg
touch -t 202001010000 artifacts/Acme.Widgets.1.0.0.nupkg
touch -t 202001020000 artifacts/Acme.Widgets.3.0.0.nupkg
touch -t 202001030000 artifacts/Acme.Widgets.2.0.0.nupkg

When call run_step "${ACTION_DIR}" "extract-version"
The status should be success
# newest by mtime is the 2.0.0 file, NOT the highest version number
Assert expect_output version "2.0.0"
Assert expect_output package_file "./artifacts/Acme.Widgets.2.0.0.nupkg"
End

It "reports version=unknown when no package exists"
When call run_step "${ACTION_DIR}" "extract-version"
The status should be success
Assert expect_output version "unknown"
Assert expect_output package_file ""
End
End

Describe "publish-package"
setup_inputs() {
  export INPUT_NAMESPACE="acme"
  export INPUT_TOKEN="ghp_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
}

It "fails with a structured error when the pack step produced nothing"
# Guards against publishing a green build that shipped no artifact at all.
setup_inputs

When call run_step "${ACTION_DIR}" "publish-package"
The status should be failure
The stdout should include "::error::No .nupkg files found"
End

It "pushes each package to the namespace feed and records the package URL"
setup_inputs
: >artifacts/Acme.Widgets.1.2.3.nupkg
# Matching on the source URL makes the mock discriminating: a regression that
# pushes to the wrong feed matches no glob and the dispatcher exits 127.
mock_command dotnet "nuget push * --source https://nuget.pkg.github.com/acme/index.json *" ""

When call run_step "${ACTION_DIR}" "publish-package"
The status should be success
Assert expect_output package_url "https://github.com/acme/packages/nuget"
End

It "fails when the push fails on both the first attempt and the retry"
# The action retries once after a warning. A persistent failure must still
# surface — swallowing it would report a successful publish that never landed.
setup_inputs
: >artifacts/Acme.Widgets.1.2.3.nupkg
mock_command dotnet "nuget push*" "" 1
mock_command sleep "*" ""

When call run_step "${ACTION_DIR}" "publish-package"
The status should be failure
The stdout should include "::warning::First publish attempt failed"
End
End
End
