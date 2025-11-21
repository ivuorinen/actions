#!/usr/bin/env shellspec
# Unit tests for php-tests action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "php-tests action"
ACTION_DIR="php-tests"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating token input"
It "accepts GitHub token expression"
When call validate_input_python "php-tests" "token" "\${{ github.token }}"
The status should be success
End

It "accepts GitHub fine-grained token"
When call validate_input_python "php-tests" "token" "ghp_abcdefghijklmnopqrstuvwxyz1234567890"
The status should be success
End

It "accepts GitHub app token"
When call validate_input_python "php-tests" "token" "ghs_abcdefghijklmnopqrstuvwxyz1234567890"
The status should be success
End

It "accepts GitHub enterprise token"
When call validate_input_python "php-tests" "token" "ghe_abcdefghijklmnopqrstuvwxyz1234567890"
The status should be success
End

It "rejects invalid token format"
When call validate_input_python "php-tests" "token" "invalid-token"
The status should be failure
End

It "rejects token with command injection"
When call validate_input_python "php-tests" "token" "ghp_token; rm -rf /"
The status should be failure
End

It "accepts empty token (uses default)"
When call validate_input_python "php-tests" "token" ""
The status should be success
End
End

Context "when validating username input"
It "accepts valid GitHub username"
When call validate_input_python "php-tests" "username" "github-actions"
The status should be success
End

It "accepts username with hyphens"
When call validate_input_python "php-tests" "username" "user-name"
The status should be success
End

It "accepts username with numbers"
When call validate_input_python "php-tests" "username" "user123"
The status should be success
End

It "accepts single character username"
When call validate_input_python "php-tests" "username" "a"
The status should be success
End

It "accepts maximum length username"
When call validate_input_python "php-tests" "username" "abcdefghijklmnopqrstuvwxyz0123456789abc"
The status should be success
End

It "rejects username too long"
When call validate_input_python "php-tests" "username" "abcdefghijklmnopqrstuvwxyz0123456789abcd"
The status should be failure
End

It "rejects username with command injection semicolon"
When call validate_input_python "php-tests" "username" "user; rm -rf /"
The status should be failure
End

It "rejects username with command injection ampersand"
When call validate_input_python "php-tests" "username" "user && rm -rf /"
The status should be failure
End

It "rejects username with command injection pipe"
When call validate_input_python "php-tests" "username" "user | rm -rf /"
The status should be failure
End

It "accepts empty username (uses default)"
When call validate_input_python "php-tests" "username" ""
The status should be success
End
End

Context "when validating email input"
It "accepts valid email"
When call validate_input_python "php-tests" "email" "user@example.com"
The status should be success
End

It "accepts email with subdomain"
When call validate_input_python "php-tests" "email" "user@mail.example.com"
The status should be success
End

It "accepts email with plus sign"
When call validate_input_python "php-tests" "email" "user+tag@example.com"
The status should be success
End

It "accepts email with numbers"
When call validate_input_python "php-tests" "email" "user123@example123.com"
The status should be success
End

It "accepts email with hyphens"
When call validate_input_python "php-tests" "email" "user-name@example-domain.com"
The status should be success
End

It "rejects email without at symbol"
When call validate_input_python "php-tests" "email" "userexample.com"
The status should be failure
End

It "rejects email without domain"
When call validate_input_python "php-tests" "email" "user@"
The status should be failure
End

It "rejects email without username"
When call validate_input_python "php-tests" "email" "@example.com"
The status should be failure
End

It "rejects email without dot in domain"
When call validate_input_python "php-tests" "email" "user@example"
The status should be failure
End

It "rejects email with spaces"
When call validate_input_python "php-tests" "email" "user @example.com"
The status should be failure
End

It "accepts empty email (uses default)"
When call validate_input_python "php-tests" "email" ""
The status should be success
End
End

Context "when checking action.yml structure"
It "has valid YAML syntax"
When call validate_action_yml_quiet "$ACTION_FILE"
The status should be success
End

It "has correct action name"
name=$(get_action_name "$ACTION_FILE")
When call echo "$name"
The output should equal "PHP Tests"
End

It "defines expected inputs"
When call get_action_inputs "$ACTION_FILE"
The output should include "token"
The output should include "username"
The output should include "email"
End

It "defines expected outputs"
When call get_action_outputs "$ACTION_FILE"
The output should include "test-status"
The output should include "tests-run"
The output should include "tests-passed"
The output should include "framework"
End
End

Context "when testing input requirements"
It "has all inputs as optional"
When call uv run "_tests/shared/validation_core.py" --property "$ACTION_FILE" "" "all_optional"
The output should equal "none"
End

It "has empty default token (runtime fallback)"
When call uv run "_tests/shared/validation_core.py" --property "$ACTION_FILE" "token" "default"
The output should equal "no-default"
End

It "has correct default username"
When call uv run "_tests/shared/validation_core.py" --property "$ACTION_FILE" "username" "default"
The output should equal "github-actions"
End

It "has correct default email"
When call uv run "_tests/shared/validation_core.py" --property "$ACTION_FILE" "email" "default"
The output should equal "github-actions@github.com"
End
End

Context "when testing security validations"
It "validates against command injection in username"
When call validate_input_python "php-tests" "username" "user\`whoami\`"
The status should be failure
End

It "validates against shell metacharacters in email"
When call validate_input_python "php-tests" "email" "user@example.com; rm -rf /"
The status should be failure
End

It "validates against variable expansion in token"
When call validate_input_python "php-tests" "token" "\${MALICIOUS_VAR}"
The status should be failure
End

It "validates against backtick injection in username"
When call validate_input_python "php-tests" "username" "user\`echo malicious\`"
The status should be failure
End
End

Context "when testing PHP-specific validations"
It "validates username length boundaries"
When call validate_input_python "php-tests" "username" "$(awk 'BEGIN{for(i=1;i<=40;i++)printf "a"}')"
The status should be failure
End

It "validates email format for Git commits"
When call validate_input_python "php-tests" "email" "noreply@github.com"
The status should be success
End

It "validates default values are secure"
When call validate_input_python "php-tests" "username" "github-actions"
The status should be success
End

It "validates default email is secure"
When call validate_input_python "php-tests" "email" "github-actions@github.com"
The status should be success
End

# Helper function that replicates the PHPUnit output parsing logic from action.yml
parse_phpunit_output() {
  local phpunit_output="$1"
  local phpunit_exit_code="$2"

  local tests_run="0"
  local tests_passed="0"

  # Pattern 1: "OK (N test(s), M assertions)" - success case (handles both singular and plural)
  if echo "$phpunit_output" | grep -qE 'OK \([0-9]+ tests?,'; then
    tests_run=$(echo "$phpunit_output" | grep -oE 'OK \([0-9]+ tests?,' | grep -oE '[0-9]+' | head -1)
    tests_passed="$tests_run"
  # Pattern 2: "Tests: N" line - failure/error/skipped case
  elif echo "$phpunit_output" | grep -qE '^Tests:'; then
    tests_run=$(echo "$phpunit_output" | grep -E '^Tests:' | grep -oE '[0-9]+' | head -1)

    # Calculate passed from failures and errors
    failures=$(echo "$phpunit_output" | grep -oE 'Failures: [0-9]+' | grep -oE '[0-9]+' | head -1 || echo "0")
    errors=$(echo "$phpunit_output" | grep -oE 'Errors: [0-9]+' | grep -oE '[0-9]+' | head -1 || echo "0")
    tests_passed=$((tests_run - failures - errors))

    # Ensure non-negative
    if [ "$tests_passed" -lt 0 ]; then
      tests_passed="0"
    fi
  fi

  # Determine status
  local status
  if [ "$phpunit_exit_code" -eq 0 ]; then
    status="success"
  else
    status="failure"
  fi

  # Output as KEY=VALUE format
  echo "tests_run=$tests_run"
  echo "tests_passed=$tests_passed"
  echo "status=$status"
}

Context "when parsing PHPUnit output"
  # Success cases
  It "parses single successful test"
    output="OK (1 test, 2 assertions)"
    When call parse_phpunit_output "$output" 0
    The line 1 of output should equal "tests_run=1"
    The line 2 of output should equal "tests_passed=1"
    The line 3 of output should equal "status=success"
  End

  It "parses multiple successful tests"
    output="OK (5 tests, 10 assertions)"
    When call parse_phpunit_output "$output" 0
    The line 1 of output should equal "tests_run=5"
    The line 2 of output should equal "tests_passed=5"
    The line 3 of output should equal "status=success"
  End

  It "parses successful tests with plural form"
    output="OK (25 tests, 50 assertions)"
    When call parse_phpunit_output "$output" 0
    The line 1 of output should equal "tests_run=25"
    The line 2 of output should equal "tests_passed=25"
    The line 3 of output should equal "status=success"
  End

  # Failure cases
  It "parses test failures"
    output="FAILURES!
Tests: 5, Assertions: 10, Failures: 2."
    When call parse_phpunit_output "$output" 1
    The line 1 of output should equal "tests_run=5"
    The line 2 of output should equal "tests_passed=3"
    The line 3 of output should equal "status=failure"
  End

  It "parses test errors"
    output="ERRORS!
Tests: 5, Assertions: 10, Errors: 1."
    When call parse_phpunit_output "$output" 2
    The line 1 of output should equal "tests_run=5"
    The line 2 of output should equal "tests_passed=4"
    The line 3 of output should equal "status=failure"
  End

  It "parses mixed failures and errors"
    output="FAILURES!
Tests: 10, Assertions: 20, Failures: 2, Errors: 1."
    When call parse_phpunit_output "$output" 1
    The line 1 of output should equal "tests_run=10"
    The line 2 of output should equal "tests_passed=7"
    The line 3 of output should equal "status=failure"
  End

  It "handles all tests failing"
    output="FAILURES!
Tests: 5, Assertions: 10, Failures: 5."
    When call parse_phpunit_output "$output" 1
    The line 1 of output should equal "tests_run=5"
    The line 2 of output should equal "tests_passed=0"
    The line 3 of output should equal "status=failure"
  End

  It "prevents negative passed count"
    output="ERRORS!
Tests: 2, Assertions: 4, Failures: 1, Errors: 2."
    When call parse_phpunit_output "$output" 2
    The line 1 of output should equal "tests_run=2"
    The line 2 of output should equal "tests_passed=0"
    The line 3 of output should equal "status=failure"
  End

  # Skipped tests
  It "parses skipped tests with success"
    output="OK, but some tests were skipped!
Tests: 5, Assertions: 8, Skipped: 2."
    When call parse_phpunit_output "$output" 0
    The line 1 of output should equal "tests_run=5"
    The line 2 of output should equal "tests_passed=5"
    The line 3 of output should equal "status=success"
  End

  # Edge cases
  It "handles no parseable output (fallback)"
    output="Some random output without test info"
    When call parse_phpunit_output "$output" 1
    The line 1 of output should equal "tests_run=0"
    The line 2 of output should equal "tests_passed=0"
    The line 3 of output should equal "status=failure"
  End

  It "handles empty output"
    output=""
    When call parse_phpunit_output "$output" 0
    The line 1 of output should equal "tests_run=0"
    The line 2 of output should equal "tests_passed=0"
    The line 3 of output should equal "status=success"
  End

  It "handles PHPUnit 10+ format with singular test"
    output="OK (1 test, 3 assertions)"
    When call parse_phpunit_output "$output" 0
    The line 1 of output should equal "tests_run=1"
    The line 2 of output should equal "tests_passed=1"
    The line 3 of output should equal "status=success"
  End

  It "handles verbose output with noise"
    output="PHPUnit 10.5.0 by Sebastian Bergmann and contributors.
Runtime:       PHP 8.3.0

.....                                                               5 / 5 (100%)

Time: 00:00.123, Memory: 10.00 MB

OK (5 tests, 10 assertions)"
    When call parse_phpunit_output "$output" 0
    The line 1 of output should equal "tests_run=5"
    The line 2 of output should equal "tests_passed=5"
    The line 3 of output should equal "status=success"
  End

  It "handles failure output with full details"
    output="PHPUnit 10.5.0 by Sebastian Bergmann and contributors.

..F..                                                               5 / 5 (100%)

Time: 00:00.234, Memory: 12.00 MB

FAILURES!
Tests: 5, Assertions: 10, Failures: 1."
    When call parse_phpunit_output "$output" 1
    The line 1 of output should equal "tests_run=5"
    The line 2 of output should equal "tests_passed=4"
    The line 3 of output should equal "status=failure"
  End

  # Status determination tests
  It "marks as success when exit code is 0"
    output="OK (3 tests, 6 assertions)"
    When call parse_phpunit_output "$output" 0
    The line 3 of output should equal "status=success"
  End

  It "marks as failure when exit code is non-zero"
    output="OK (3 tests, 6 assertions)"
    When call parse_phpunit_output "$output" 1
    The line 3 of output should equal "status=failure"
  End

  It "handles skipped tests without OK prefix"
    output="Tests: 5, Assertions: 8, Skipped: 2."
    When call parse_phpunit_output "$output" 0
    The line 1 of output should equal "tests_run=5"
    The line 2 of output should equal "tests_passed=5"
    The line 3 of output should equal "status=success"
  End

  It "handles risky tests output"
    output="FAILURES!
Tests: 8, Assertions: 15, Failures: 1, Risky: 2."
    When call parse_phpunit_output "$output" 1
    The line 1 of output should equal "tests_run=8"
    The line 2 of output should equal "tests_passed=7"
    The line 3 of output should equal "status=failure"
  End
End
End
End
