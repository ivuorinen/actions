#!/usr/bin/env shellspec
# actions/setup-python with `cache:` throws when no file in the checked-out repo
# matches the cache dependency glob ("No file in ... matched to [...]"). The action
# installs its own tool, so a caller without a requirements file must still pass.
# setup-python is a `uses:` step the harness skips, so the inputs are asserted
# against action.yml.

Describe "ansible-lint-fix setup-python"
ACTION_DIR="${PROJECT_ROOT}/ansible-lint-fix"

It "does not enable the setup-python dependency cache"
When call grep -E '^[[:space:]]+cache(-dependency-path)?:' "${ACTION_DIR}/action.yml"
The status should be failure
The stdout should equal ""
End
End
