#!/usr/bin/env shellspec
# python-lint-fix chooses its own lint tools, so they come from the hash-locked
# requirements file shipped with the action and not from what the package index
# serves on the day. The harness runs the real install step against a pip stub
# that only answers the locked command, so any other pip call fails the step.

Describe "python-lint-fix locked install"
ACTION_DIR="${PROJECT_ROOT}/python-lint-fix"

before() {
  shellspec_setup_test_env "python-lint-fix-lockfile-$$"
  harness_reset
  export INPUT_MAX_RETRIES="3"
  mkdir -p .venv/bin
  : >.venv/bin/activate
  mock_command python "-m venv .venv" ""
  mock_command pip "install --require-hashes --only-binary=:all: --retries 3 -r ${ACTION_DIR}/requirements.lock.txt" "locked install"
  mock_command flake8 "--version" "7.0.0"
  mock_command autopep8 "--version" "2.0.4"
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "python-lint-fix-lockfile-$$"
  harness_reset
}
AfterEach 'after'

It "installs only from the action's hash-locked requirements file"
When call run_step "${ACTION_DIR}" "install"
The status should be success
The stdout should include "locked install"
End

It "does not let the deprecated version inputs change what is installed"
export INPUT_FLAKE8_VERSION="6.1.0"
export INPUT_AUTOPEP8_VERSION="2.0.0"
When call run_step "${ACTION_DIR}" "install"
The status should be success
The stdout should include "locked install"
End

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
