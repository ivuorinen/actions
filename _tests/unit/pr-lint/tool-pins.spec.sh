#!/usr/bin/env shellspec
# pr-lint activates pinned package managers for repositories that declare none. The corepack
# mock matches only the exact spec, so a floating one exits 127 and fails the example.

Describe "pr-lint tool pins"
ACTION_DIR="${PROJECT_ROOT}/pr-lint"

before() {
  shellspec_setup_test_env "pr-lint-pins-$$"
  harness_reset
  mock_command corepack "enable" ""
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "pr-lint-pins-$$"
  harness_reset
}
AfterEach 'after'

It "prepares the pinned pnpm"
use_package_manager pnpm
mock_command corepack "prepare pnpm@$(pinned_version pr-lint PNPM_VERSION) --activate" ""
When call run_step "${ACTION_DIR}" "install-pm"
The status should be success
The stdout should include "using detected package manager: pnpm"
End

It "prepares the pinned Yarn"
use_package_manager yarn
mock_command corepack "prepare yarn@$(pinned_version pr-lint YARN_VERSION) --activate" ""
When call run_step "${ACTION_DIR}" "install-pm"
The status should be success
The stdout should include "using detected package manager: yarn"
End

It "sets up the pinned Bun"
The contents of file "${ACTION_DIR}/action.yml" should include 'bun-version: ${{ env.BUN_VERSION }}'
End

# Composer 2.3 and later need PHP 7.2.5; the 2.2 LTS line still runs on older PHP.
Describe "choosing Composer for the PHP version"
Parameters
"5.6" "COMPOSER_LTS_VERSION"
"7.1" "COMPOSER_LTS_VERSION"
"7.2" "COMPOSER_TOOL_VERSION"
"8.4" "COMPOSER_TOOL_VERSION"
End

It "picks $2 for PHP $1"
printf '%s\n' "$1" >.php-version
When call run_step "${ACTION_DIR}" "php-version"
The status should be success
The stderr should include "Found PHP version in .php-version: $1"
Assert expect_output composer-version "$(pinned_version pr-lint "$2")"
End
End

It "sets up the Composer the detect step chose"
The contents of file "${ACTION_DIR}/action.yml" should include 'tools: composer:${{ steps.php-version.outputs.composer-version }}'
End
End
