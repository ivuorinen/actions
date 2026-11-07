#!/usr/bin/env shellspec
# ansible-lint-fix chooses its own lint tool, so it and every transitive
# dependency come from the hash-locked requirements file shipped with the action.
# The install runs inside nick-fields/retry, a `uses:` step the harness skips, so
# the command is asserted against action.yml.

Describe "ansible-lint-fix locked install"
ACTION_DIR="${PROJECT_ROOT}/ansible-lint-fix"

It "installs only from the action's hash-locked requirements file"
When call grep -F 'pip install --require-hashes --only-binary=:all: -r "$ACTION_PATH/requirements.lock.txt"' "${ACTION_DIR}/action.yml"
The status should be success
The stdout should include "--require-hashes"
End

# The lock holds wheels for one Python, so a bump of the Python the action sets up
# must fail here until the lock is regenerated for it.
It "locks for the Python version the action sets up"
setup_version=$(sed -n "s/^ *python-version: '\(.*\)'$/\1/p" "${ACTION_DIR}/action.yml")
When call grep -F -- "--python-version=${setup_version} " "${ACTION_DIR}/requirements.lock.txt"
The status should be success
The stdout should include "uv pip compile"
End

It "passes the action's own directory to the install step"
When call grep -F 'ACTION_PATH: ${{ github.action_path }}' "${ACTION_DIR}/action.yml"
The status should be success
The stdout should include "ACTION_PATH"
End

It "ships a complete lock"
When call requirements_lock_problems "${ACTION_DIR}"
The status should be success
The stdout should equal ""
End
End
