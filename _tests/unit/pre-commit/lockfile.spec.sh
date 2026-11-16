#!/usr/bin/env shellspec
# pre-commit chooses the pre-commit version it installs, so it and every transitive
# dependency come from the hash-locked requirements file shipped with the action.
# behavior.spec.sh runs the install step and checks the pip command; these examples
# check the lock itself.

Describe "pre-commit locked install"
ACTION_DIR="${PROJECT_ROOT}/pre-commit"

It "pins pre-commit in requirements.in, where Renovate's pip-compile manager updates it"
When call grep -E '^pre-commit==[0-9]+\.[0-9]+\.[0-9]+$' "${ACTION_DIR}/requirements.in"
The status should be success
The stdout should start with "pre-commit=="
End

# The lock holds wheels for one Python, so a bump of the Python the action sets up
# must fail here until the lock is regenerated for it.
It "locks for the Python version the action sets up"
setup_version=$(sed -n "s/^ *python-version: '\(.*\)'$/\1/p" "${ACTION_DIR}/action.yml")
When call grep -F -- "--python-version=${setup_version} " "${ACTION_DIR}/requirements.lock.txt"
The status should be success
The stdout should include "uv pip compile"
End

It "ships a complete lock"
When call requirements_lock_problems "${ACTION_DIR}"
The status should be success
The stdout should equal ""
End
End
