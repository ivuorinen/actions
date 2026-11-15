#!/usr/bin/env shellspec
# npm-semantic-release activates pinned package managers and tells the upstream action which
# semantic-release to install: with no semantic_version it installs the newest one. The
# corepack mock matches only the exact spec, so a floating one exits 127 and fails the example.

Describe "npm-semantic-release tool pins"
ACTION_DIR="${PROJECT_ROOT}/npm-semantic-release"

before() {
  shellspec_setup_test_env "npm-semantic-release-pins-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "npm-semantic-release-pins-$$"
  harness_reset
}
AfterEach 'after'

It "prepares the pinned pnpm"
use_package_manager pnpm
mock_command corepack "prepare pnpm@$(pinned_version npm-semantic-release PNPM_VERSION) --activate" ""
When call run_step "${ACTION_DIR}" "install-pm"
The status should be success
End

It "prepares the pinned Yarn"
use_package_manager yarn
mock_command corepack "prepare yarn@$(pinned_version npm-semantic-release YARN_VERSION) --activate" ""
When call run_step "${ACTION_DIR}" "install-pm"
The status should be success
End

It "sets up the pinned Bun"
The contents of file "${ACTION_DIR}/action.yml" should include 'bun-version: ${{ env.BUN_VERSION }}'
End

It "passes semantic-release's pinned version to the upstream action"
The contents of file "${ACTION_DIR}/action.yml" should include 'semantic_version: ${{ env.SEMANTIC_RELEASE_VERSION }}'
End

It "falls back to the pinned plugin only when the caller names none"
The contents of file "${ACTION_DIR}/action.yml" should include \
  "extra_plugins: \${{ inputs.extra_plugins || format('conventional-changelog-conventionalcommits@{0}', env.CONVENTIONAL_COMMITS_VERSION) }}"
End
End
