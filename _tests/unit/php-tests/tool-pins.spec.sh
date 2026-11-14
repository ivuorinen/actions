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

# Composer 2.3 and later need PHP 7.2.5; the 2.2 LTS line still runs on older PHP.
Describe "choosing Composer for the PHP version"
Parameters
"5.6" "COMPOSER_LTS_VERSION"
"7.0" "COMPOSER_LTS_VERSION"
"7.1" "COMPOSER_LTS_VERSION"
"7.2" "COMPOSER_TOOL_VERSION"
"7.4" "COMPOSER_TOOL_VERSION"
"8.5" "COMPOSER_TOOL_VERSION"
End

It "picks $2 for PHP $1"
printf '%s\n' "$1" >.php-version
When call run_step "${ACTION_DIR}" "detect-php-version"
The status should be success
The stderr should include "Found PHP version in .php-version: $1"
Assert expect_output composer-version "$(pinned_version php-tests "$2")"
End
End

# setup-php can read a bare 7 as 7.0, which Composer 2.3 and later cannot run on.
It "picks the LTS Composer when the caller asks for PHP 7"
export INPUT_PHP_VERSION="7"
When call run_step "${ACTION_DIR}" "detect-php-version"
The status should be success
The stderr should include "Using default PHP version: 7"
Assert expect_output composer-version "$(pinned_version php-tests COMPOSER_LTS_VERSION)"
End

It "picks the current Composer for the pinned PHP"
When call run_step "${ACTION_DIR}" "detect-php-version"
The status should be success
The stderr should include "Using default PHP version"
Assert expect_output composer-version "$(pinned_version php-tests COMPOSER_TOOL_VERSION)"
End
End

It "sets up the Composer the detect step chose"
The contents of file "${ACTION_DIR}/action.yml" should include 'tools: composer:${{ steps.detect-php-version.outputs.composer-version }}'
End
End
