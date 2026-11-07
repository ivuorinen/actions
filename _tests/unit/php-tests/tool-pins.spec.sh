#!/usr/bin/env shellspec
# php-tests falls back to a pinned PHP when the repository states no version, and tells setup-php
# which Composer to install: with no version it installs the newest one.

Describe "php-tests tool pins"
ACTION_DIR="${PROJECT_ROOT}/php-tests"

before() {
  shellspec_setup_test_env "php-tests-pins-$$"
  harness_reset
}
BeforeEach 'before'

after() {
  shellspec_cleanup_test_env "php-tests-pins-$$"
  harness_reset
}
AfterEach 'after'

Describe "Detect PHP Version"
It "falls back to the pin when neither the repository nor the caller names a version"
When call run_step "${ACTION_DIR}" "detect-php-version"
The status should be success
The stderr should include "Using default PHP version"
Assert expect_output detected-version "$(pinned_version php-tests DEFAULT_VERSION)"
End

Describe "when the caller names a version"
Parameters
"8.4"
"latest"
End

It "falls back to $1"
export INPUT_PHP_VERSION="$1"
When call run_step "${ACTION_DIR}" "detect-php-version"
The status should be success
The stderr should include "Using default PHP version: $1"
Assert expect_output detected-version "$1"
End
End

It "prefers what the repository states"
printf '8.2\n' >.php-version
When call run_step "${ACTION_DIR}" "detect-php-version"
The status should be success
The stderr should include "Found PHP version in .php-version: 8.2"
Assert expect_output detected-version "8.2"
End
End

It "sets up the pinned Composer"
The contents of file "${ACTION_DIR}/action.yml" should include 'tools: composer:${{ env.COMPOSER_TOOL_VERSION }}'
End
End
