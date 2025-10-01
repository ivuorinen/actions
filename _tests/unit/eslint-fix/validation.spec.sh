#!/usr/bin/env shellspec
# Unit tests for eslint-fix action validation and logic
# Framework is automatically loaded via spec_helper.sh

Describe "eslint-fix action"
  ACTION_DIR="eslint-fix"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating token input"
    It "accepts valid GitHub token"
      When call validate_input_python "eslint-fix" "token" "ghp_123456789012345678901234567890123456"
      The status should be success
    End
    It "rejects injection in token"
      When call validate_input_python "eslint-fix" "token" "token; rm -rf /"
      The status should be failure
    End
  End

  Context "when validating username input"
    It "accepts valid username"
      When call validate_input_python "eslint-fix" "username" "github-actions"
      The status should be success
    End
    It "rejects injection in username"
      When call validate_input_python "eslint-fix" "username" "user; rm -rf /"
      The status should be failure
    End
  End

  Context "when validating email input"
    It "accepts valid email"
      When call validate_input_python "eslint-fix" "email" "test@example.com"
      The status should be success
    End
    It "rejects invalid email format"
      When call validate_input_python "eslint-fix" "email" "invalid-email"
      The status should be failure
    End
  End

  Context "when validating numeric inputs"
    It "accepts valid max-retries"
      When call validate_input_python "eslint-fix" "max-retries" "3"
      The status should be success
    End
    It "accepts minimum retries"
      When call validate_input_python "eslint-fix" "max-retries" "1"
      The status should be success
    End
    It "accepts maximum retries"
      When call validate_input_python "eslint-fix" "max-retries" "10"
      The status should be success
    End
    It "rejects zero retries"
      When call validate_input_python "eslint-fix" "max-retries" "0"
      The status should be failure
    End
    It "rejects retries above limit"
      When call validate_input_python "eslint-fix" "max-retries" "15"
      The status should be failure
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
      When call validate_input_python "eslint-fix" "token" "invalid-token;rm -rf /"
      The status should be failure
    End

    It "validates email format"
      When call validate_input_python "eslint-fix" "email" "invalid@email"
      The status should be failure
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
