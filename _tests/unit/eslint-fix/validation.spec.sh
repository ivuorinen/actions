#!/usr/bin/env shellspec
# Unit tests for eslint-fix action validation and logic
# Framework is automatically loaded via spec_helper.sh

Describe "eslint-fix action"
  ACTION_DIR="eslint-fix"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating token input"
    It "accepts valid GitHub token"
      When call test_input_validation "$ACTION_DIR" "token" "ghp_123456789012345678901234567890123456" "success"
      The status should be success
    End
    It "rejects injection in token"
      When call test_input_validation "$ACTION_DIR" "token" "token; rm -rf /" "failure"
      The status should be success
    End
  End

  Context "when validating username input"
    It "accepts valid username"
      When call test_input_validation "$ACTION_DIR" "username" "github-actions" "success"
      The status should be success
    End
    It "rejects injection in username"
      When call test_input_validation "$ACTION_DIR" "username" "user; rm -rf /" "failure"
      The status should be success
    End
  End

  Context "when validating email input"
    It "accepts valid email"
      When call test_input_validation "$ACTION_DIR" "email" "test@example.com" "success"
      The status should be success
    End
    It "rejects invalid email format"
      When call test_input_validation "$ACTION_DIR" "email" "invalid-email" "failure"
      The status should be success
    End
  End

  Context "when validating numeric inputs"
    It "accepts valid max-retries"
      When call test_input_validation "$ACTION_DIR" "max-retries" "3" "success"
      The status should be success
    End
    It "accepts minimum retries"
      When call test_input_validation "$ACTION_DIR" "max-retries" "1" "success"
      The status should be success
    End
    It "accepts maximum retries"
      When call test_input_validation "$ACTION_DIR" "max-retries" "10" "success"
      The status should be success
    End
    It "rejects zero retries"
      When call test_input_validation "$ACTION_DIR" "max-retries" "0" "failure"
      The status should be success
    End
    It "rejects retries above limit"
      When call test_input_validation "$ACTION_DIR" "max-retries" "15" "failure"
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
      The output should equal "ESLint Fix"
    End

    It "defines required inputs"
      inputs=$(get_action_inputs "$ACTION_FILE")
      When call echo "$inputs"
      The output should include "token"
      The output should include "username"
      The output should include "email"
      The output should include "max-retries"
    End

    It "defines expected outputs"
      outputs=$(get_action_outputs "$ACTION_FILE")
      When call echo "$outputs"
      The output should include "files_changed"
      The output should include "lint_status"
      The output should include "errors_fixed"
    End
  End

  Context "when validating security"
    It "validates token format"
      When call test_input_validation "$ACTION_DIR" "token" "invalid-token;rm -rf /" "failure"
      The status should be success
    End

    It "validates email format"
      When call test_input_validation "$ACTION_DIR" "email" "invalid@email" "failure"
      The status should be success
    End
  End

  Context "when testing outputs"
    It "produces all expected outputs"
      When call test_action_outputs "$ACTION_DIR" "token" "ghp_test" "username" "test" "email" "test@example.com" "max-retries" "3"
      The status should be success
      The stderr should include "Testing action outputs for: eslint-fix"
      The stderr should include "Output test passed for: eslint-fix"
    End
  End
End
