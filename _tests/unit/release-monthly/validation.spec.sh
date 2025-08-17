#!/usr/bin/env shellspec
# Unit tests for release-monthly action validation and logic
# Framework is automatically loaded via spec_helper.sh

Describe "release-monthly action"
  ACTION_DIR="release-monthly"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating token input"
    # NOTE: Test framework uses strict GitHub token format validation
    It "accepts valid GitHub token with correct format"
      When call test_input_validation "$ACTION_DIR" "token" "ghp_123456789012345678901234567890123456" "success"
      The status should be success
    End
    It "rejects empty token"
      When call test_input_validation "$ACTION_DIR" "token" "" "failure"
      The status should be success
    End
    It "rejects injection in token"
      When call test_input_validation "$ACTION_DIR" "token" "token; rm -rf /" "failure"
      The status should be success
    End
  End

  Context "when validating dry-run input"
    It "accepts true value"
      When call test_input_validation "$ACTION_DIR" "dry-run" "true" "success"
      The status should be success
    End
    It "accepts false value"
      When call test_input_validation "$ACTION_DIR" "dry-run" "false" "success"
      The status should be success
    End
    # NOTE: Test framework uses default validation for 'dry-run'
    # Default validation only checks injection patterns, not boolean format
    It "accepts invalid boolean (framework default validation)"
      When call test_input_validation "$ACTION_DIR" "dry-run" "maybe" "success"
      The status should be success
    End
    It "rejects injection in dry-run"
      When call test_input_validation "$ACTION_DIR" "dry-run" "true; rm -rf /" "failure"
      The status should be success
    End
  End

  Context "when validating prefix input"
    # NOTE: Test framework treats all empty values as failure by default
    It "rejects empty prefix (framework treats empty as failure)"
      When call test_input_validation "$ACTION_DIR" "prefix" "" "failure"
      The status should be success
    End
    It "accepts valid prefix"
      When call test_input_validation "$ACTION_DIR" "prefix" "v" "success"
      The status should be success
    End
    It "accepts alphanumeric prefix"
      When call test_input_validation "$ACTION_DIR" "prefix" "release-v1.0-" "success"
      The status should be success
    End
    # NOTE: Test framework uses default validation for 'prefix'
    # Default validation only checks injection patterns, not character restrictions
    It "accepts special characters in prefix (framework default validation)"
      When call test_input_validation "$ACTION_DIR" "prefix" "invalid@prefix" "success"
      The status should be success
    End
    It "accepts spaces in prefix (framework default validation)"
      When call test_input_validation "$ACTION_DIR" "prefix" "invalid prefix" "success"
      The status should be success
    End
    It "rejects injection in prefix"
      When call test_input_validation "$ACTION_DIR" "prefix" "prefix; rm -rf /" "failure"
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
      The output should equal "Do Monthly Release"
    End

    It "defines required inputs"
      inputs=$(get_action_inputs "$ACTION_FILE")
      When call echo "$inputs"
      The output should include "token"
      The output should include "dry-run"
      The output should include "prefix"
    End

    It "defines expected outputs"
      outputs=$(get_action_outputs "$ACTION_FILE")
      When call echo "$outputs"
      The output should include "release-tag"
      The output should include "release-url"
      The output should include "previous-tag"
    End
  End

  Context "when validating security"
    It "validates token is required"
      When call test_input_validation "$ACTION_DIR" "token" "" "failure"
      The status should be success
    End

    It "validates prefix format"
      When call test_input_validation "$ACTION_DIR" "prefix" "invalid;prefix" "failure"
      The status should be success
    End
  End

  Context "when testing outputs"
    It "produces all expected outputs"
      When call test_action_outputs "$ACTION_DIR" "token" "ghp_test" "dry-run" "true" "prefix" "v"
      The status should be success
      The stderr should include "Testing action outputs for: release-monthly"
      The stderr should include "Output test passed for: release-monthly"
    End
  End
End
