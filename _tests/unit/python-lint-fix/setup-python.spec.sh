#!/usr/bin/env shellspec
# actions/setup-python with `cache:` throws when no file in the checked-out repo
# matches the cache dependency glob ("No file in ... matched to [...]"), and the
# poetry and pipenv caches also need that tool on PATH, which the action never
# installs. The action installs its own tools into a venv, so a caller without
# a requirements file must still pass. setup-python is a `uses:` step the harness
# skips, so the inputs are asserted against action.yml.

Describe "python-lint-fix setup-python"
ACTION_DIR="${PROJECT_ROOT}/python-lint-fix"

It "does not enable the setup-python dependency cache"
When call grep -E '^[[:space:]]+cache(-dependency-path)?:' "${ACTION_DIR}/action.yml"
The status should be failure
The stdout should equal ""
End

It "sets Python up once, with the detected version"
When call grep -c 'uses: actions/setup-python@' "${ACTION_DIR}/action.yml"
The status should be success
The stdout should equal "1"
End

It "does not detect a package manager that nothing consumes"
When call grep -E 'package-manager|package_manager' "${ACTION_DIR}/action.yml"
The status should be failure
The stdout should equal ""
End
End
