#!/usr/bin/env shellspec
# python-lint-fix chooses its own lint tools, so they come from the hash-locked
# requirements file shipped with the action and not from what the package index
# serves on the day. behavior.spec.sh runs the install step and checks the pip
# command; these examples check the inputs it replaces and the lock itself.

Describe "python-lint-fix locked install"
ACTION_DIR="${PROJECT_ROOT}/python-lint-fix"

It "warns callers that set the deprecated version inputs"
When call grep -c 'deprecationMessage:' "${ACTION_DIR}/action.yml"
The status should be success
The stdout should equal "2"
End

It "ships a complete lock"
When call requirements_lock_problems "${ACTION_DIR}"
The status should be success
The stdout should equal ""
End
End
