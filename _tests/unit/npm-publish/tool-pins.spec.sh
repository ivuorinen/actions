#!/usr/bin/env shellspec
# npm-publish activates pinned package managers. The corepack mock matches only the exact spec,
# so a floating or differently pinned one exits 127 and fails the example.

Describe "npm-publish tool pins"
ACTION_DIR="${PROJECT_ROOT}/npm-publish"

before() {
  shellspec_setup_test_env "npm-publish-pins-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "npm-publish-pins-$$"
  harness_reset
}
AfterEach 'after'

It "prepares the pinned pnpm"
use_package_manager pnpm
mock_command corepack "prepare pnpm@$(pinned_version npm-publish PNPM_VERSION) --activate" ""
When call run_step "${ACTION_DIR}" "install-pm"
The status should be success
End

It "prepares the pinned Yarn"
use_package_manager yarn
mock_command corepack "prepare yarn@$(pinned_version npm-publish YARN_VERSION) --activate" ""
When call run_step "${ACTION_DIR}" "install-pm"
The status should be success
End

It "sets up the pinned Bun"
The contents of file "${ACTION_DIR}/action.yml" should include 'bun-version: ${{ env.BUN_VERSION }}'
End
End
