#!/usr/bin/env shellspec
# eslint-lint runs the repository's own ESLint when it has one, and otherwise installs a pinned
# copy instead of letting npx or bunx fetch whatever is newest. Mocks match exact arguments, so
# anything else exits 127 and fails the example.

Describe "eslint-lint tool pins"
ACTION_DIR="${PROJECT_ROOT}/eslint-lint"

before() {
  shellspec_setup_test_env "eslint-lint-pins-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "eslint-lint-pins-$$"
  harness_reset
}
AfterEach 'after'

Describe "Install Package Manager"
It "prepares the pinned pnpm"
use_package_manager pnpm
mock_command corepack "prepare pnpm@$(pinned_version eslint-lint PNPM_VERSION) --activate" ""
When call run_step "${ACTION_DIR}" "install-pm"
The status should be success
End

It "prepares the pinned Yarn"
use_package_manager yarn
mock_command corepack "prepare yarn@$(pinned_version eslint-lint YARN_VERSION) --activate" ""
When call run_step "${ACTION_DIR}" "install-pm"
The status should be success
End
End

It "sets up the pinned Bun"
The contents of file "${ACTION_DIR}/action.yml" should include 'bun-version: ${{ env.BUN_VERSION }}'
End

Describe "Ensure ESLint"
Describe "when the repository has its own copy"
Parameters
# package manager, command, its arguments when asked for the version
"npm" "npx" "--no-install eslint"
"pnpm" "pnpm" "exec eslint"
"yarn" "yarn" "eslint"
"bun" "bunx" "--no-install eslint"
End

It "runs it with $1 and installs nothing"
use_package_manager "$1"
mock_command "$2" "$3 --version" "v9.0.0"
mock_command npm "root -g" "/opt/node/lib/node_modules"
When call run_step "${ACTION_DIR}" "ensure-eslint"
The status should be success
Assert expect_output command "$2 $3"
Assert expect_output node-path "/opt/node/lib/node_modules"
End
End

Describe "when the repository has no copy"
install_args() {
  printf 'install -g eslint@%s @microsoft/eslint-formatter-sarif@%s' \
    "$1" "$(pinned_version eslint-lint ESLINT_FORMATTER_SARIF_VERSION)"
}

before_missing() {
  use_package_manager npm
  mock_command npx "--no-install eslint --version" "" 1
  mock_command npm "root -g" "/opt/node/lib/node_modules"
}
BeforeEach 'before_missing'

It "installs the pinned version and runs that"
mock_command npm "$(install_args "$(pinned_version eslint-lint DEFAULT_ESLINT_VERSION)")" ""
When call run_step "${ACTION_DIR}" "ensure-eslint"
The status should be success
Assert expect_output command "eslint"
Assert expect_output node-path "/opt/node/lib/node_modules"
End

Parameters
"9.39.1"
"latest"
End

It "installs $1 when the caller asks for it"
export INPUT_ESLINT_VERSION="$1"
mock_command npm "$(install_args "$1")" ""
When call run_step "${ACTION_DIR}" "ensure-eslint"
The status should be success
Assert expect_output command "eslint"
End
End

It "fails the step when the pinned version cannot be installed"
use_package_manager npm
mock_command npx "--no-install eslint --version" "" 1
mock_command npm "install -g *" "" 1
When call run_step "${ACTION_DIR}" "ensure-eslint"
The status should be failure
End
End

Describe "running the resolved command"
before_run() {
  export HARNESS_STEPS='{"ensure-eslint":{"outputs":{"command":"npx --no-install eslint","node-path":""}}}'
  export INPUT_FILE_EXTENSIONS=".js"
}
BeforeEach 'before_run'

It "checks with it"
export INPUT_CONFIG_FILE=".eslintrc" INPUT_CACHE="false" INPUT_MAX_WARNINGS="0"
export INPUT_REPORT_FORMAT="stylish" INPUT_FAIL_ON_ERROR="true"
mock_command npx "--no-install eslint . --ext .js --max-warnings 0 --format stylish" ""
When call run_step "${ACTION_DIR}" "check"
The status should be success
The stdout should include "ESLint check completed"
Assert expect_output status success
End

It "fixes with it"
mock_command npx "--no-install eslint . --ext .js --fix" ""
mock_command git "diff *" ""
When call run_step "${ACTION_DIR}" "fix"
The status should be success
The stdout should include "ESLint fix completed"
Assert expect_output status success
End
End
End
