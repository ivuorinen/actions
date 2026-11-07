#!/usr/bin/env shellspec
# prettier-lint runs the repository's own Prettier when it has one, and otherwise installs a
# pinned copy instead of letting npx fetch whatever is newest. Mocks match exact arguments, so
# anything else exits 127 and fails the example.

Describe "prettier-lint tool pins"
ACTION_DIR="${PROJECT_ROOT}/prettier-lint"

before() {
  shellspec_setup_test_env "prettier-lint-pins-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "prettier-lint-pins-$$"
  harness_reset
}
AfterEach 'after'

Describe "Install Package Manager"
It "prepares the pinned pnpm"
use_package_manager pnpm
mock_command corepack "prepare pnpm@$(pinned_version prettier-lint PNPM_VERSION) --activate" ""
When call run_step "${ACTION_DIR}" "install-pm"
The status should be success
End

It "prepares the pinned Yarn"
use_package_manager yarn
mock_command corepack "prepare yarn@$(pinned_version prettier-lint YARN_VERSION) --activate" ""
When call run_step "${ACTION_DIR}" "install-pm"
The status should be success
End
End

It "sets up the pinned Bun"
The contents of file "${ACTION_DIR}/action.yml" should include 'bun-version: ${{ env.BUN_VERSION }}'
End

Describe "Ensure Prettier"
It "installs nothing when the repository has its own copy"
mock_command npx "--no-install prettier --version" "3.0.0"
When call run_step "${ACTION_DIR}" "ensure-prettier"
The status should be success
End

Describe "when the repository has no copy"
before_missing() {
  mock_command npx "--no-install prettier --version" "" 1
}
BeforeEach 'before_missing'

It "installs the pinned version"
mock_command npm "install -g prettier@$(pinned_version prettier-lint DEFAULT_PRETTIER_VERSION)" ""
When call run_step "${ACTION_DIR}" "ensure-prettier"
The status should be success
End

Parameters
"3.0.0"
"latest"
End

It "installs $1 when the caller asks for it"
export INPUT_PRETTIER_VERSION="$1"
mock_command npm "install -g prettier@$1" ""
When call run_step "${ACTION_DIR}" "ensure-prettier"
The status should be success
End
End

It "fails the step when the pinned version cannot be installed"
mock_command npx "--no-install prettier --version" "" 1
mock_command npm "install -g *" "" 1
When call run_step "${ACTION_DIR}" "ensure-prettier"
The status should be failure
End
End

Describe "running Prettier"
It "checks without letting npx fetch it"
export INPUT_CONFIG_FILE=".prettierrc" INPUT_CACHE="false" INPUT_FAIL_ON_ERROR="true"
export INPUT_FILE_PATTERN="**/*.js"
mock_command npx "--no-install prettier --check **/*.js" ""
When call run_step "${ACTION_DIR}" "check"
The status should be success
The stdout should include "Prettier check completed"
Assert expect_output status success
End

It "fixes without letting npx fetch it"
export INPUT_FILE_PATTERN="**/*.js"
mock_command npx "--no-install prettier --write **/*.js" ""
mock_command git "status --porcelain" ""
When call run_step "${ACTION_DIR}" "fix"
The status should be success
The stdout should include "Prettier fix completed"
Assert expect_output status success
End
End
End
