#!/usr/bin/env shellspec
# Unit tests for biome-fix action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "biome-fix action"
  ACTION_DIR="biome-fix"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating token input"
    It "accepts personal access token"
      When call test_input_validation "$ACTION_DIR" "token" "ghp_123456789012345678901234567890123456" "success"
      The status should be success
    End
    It "accepts organization token"
      When call test_input_validation "$ACTION_DIR" "token" "gho_123456789012345678901234567890123456" "success"
      The status should be success
    End
    It "accepts user token"
      When call test_input_validation "$ACTION_DIR" "token" "ghu_123456789012345678901234567890123456" "success"
      The status should be success
    End
    It "accepts server token"
      When call test_input_validation "$ACTION_DIR" "token" "ghs_123456789012345678901234567890123456" "success"
      The status should be success
    End
    It "accepts refresh token"
      When call test_input_validation "$ACTION_DIR" "token" "ghr_123456789012345678901234567890123456" "success"
      The status should be success
    End
  End

  Context "when validating email input"
    It "accepts valid email"
      When call test_input_validation "$ACTION_DIR" "email" "test@example.com" "success"
      The status should be success
    End
    It "rejects invalid email without @"
      When call test_input_validation "$ACTION_DIR" "email" "testexample.com" "failure"
      The status should be success
    End
    It "rejects invalid email without domain"
      When call test_input_validation "$ACTION_DIR" "email" "test@" "failure"
      The status should be success
    End
  End

  Context "when validating username input"
    It "accepts valid username"
      When call test_input_validation "$ACTION_DIR" "username" "github-actions" "success"
      The status should be success
    End
    It "rejects semicolon injection"
      When call test_input_validation "$ACTION_DIR" "username" "user;rm -rf /" "failure"
      The status should be success
    End
    It "rejects ampersand injection"
      When call test_input_validation "$ACTION_DIR" "username" "user&&malicious" "failure"
      The status should be success
    End
    It "rejects pipe injection"
      When call test_input_validation "$ACTION_DIR" "username" "user|dangerous" "failure"
      The status should be success
    End
    It "rejects overly long username"
      When call test_input_validation "$ACTION_DIR" "username" "this-username-is-definitely-too-long-for-github-maximum-length-limit" "failure"
      The status should be success
    End
  End

  Context "when validating max-retries input"
    It "accepts valid retry count"
      When call test_input_validation "$ACTION_DIR" "max-retries" "5" "success"
      The status should be success
    End
    It "rejects zero retries"
      When call test_input_validation "$ACTION_DIR" "max-retries" "0" "failure"
      The status should be success
    End
    It "rejects negative retries"
      When call test_input_validation "$ACTION_DIR" "max-retries" "-1" "failure"
      The status should be success
    End
    It "rejects retries above limit"
      When call test_input_validation "$ACTION_DIR" "max-retries" "15" "failure"
      The status should be success
    End
    It "rejects non-numeric retries"
      When call test_input_validation "$ACTION_DIR" "max-retries" "invalid" "failure"
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
      The output should equal "Biome Fix"
    End

    It "defines expected inputs"
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
      The output should include "fix_status"
    End
  End

  Context "when validating security"
    It "rejects command injection in token"
      When call test_input_validation "$ACTION_DIR" "token" "ghp_123;rm -rf /" "failure"
      The status should be success
    End

    It "rejects command injection in email"
      When call test_input_validation "$ACTION_DIR" "email" "user@domain.com;rm -rf /" "failure"
      The status should be success
    End

    It "validates all inputs for injection patterns"
      When call test_input_validation "$ACTION_DIR" "max-retries" "3;malicious" "failure"
      The status should be success
    End
  End

  Context "when testing outputs"
    It "produces all expected outputs consistently"
      When call test_action_outputs "$ACTION_DIR" "token" "ghp_123456789012345678901234567890123456" "username" "github-actions" "email" "test@example.com" "max-retries" "3"
      The status should be success
      The stderr should include "Testing action outputs for: biome-fix"
      The stderr should include "Output test passed for: biome-fix"
    End
  End
End
