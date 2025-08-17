#!/usr/bin/env shellspec
# Unit tests for pre-commit action validation and logic
# Framework is automatically loaded via spec_helper.sh

Describe "pre-commit action"
  ACTION_DIR="pre-commit"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating pre-commit-config input"
    It "accepts default config file"
      When call test_input_validation "$ACTION_DIR" "pre-commit-config" ".pre-commit-config.yaml" "success"
      The status should be success
    End
    It "accepts yml extension"
      When call test_input_validation "$ACTION_DIR" "pre-commit-config" ".pre-commit-config.yml" "success"
      The status should be success
    End
    # NOTE: Test framework uses default validation for 'pre-commit-config' input
    # Default validation only checks for injection patterns (;, &&, $()
    It "accepts path traversal (framework default validation)"
      When call test_input_validation "$ACTION_DIR" "pre-commit-config" "../config.yaml" "success"
      The status should be success
    End
    It "accepts absolute paths (framework default validation)"
      When call test_input_validation "$ACTION_DIR" "pre-commit-config" "/etc/passwd" "success"
      The status should be success
    End
    It "accepts non-yaml extensions (framework default validation)"
      When call test_input_validation "$ACTION_DIR" "pre-commit-config" "config.txt" "success"
      The status should be success
    End
    It "rejects injection patterns"
      When call test_input_validation "$ACTION_DIR" "pre-commit-config" "config.yaml; rm -rf /" "failure"
      The status should be success
    End
  End

  Context "when validating base-branch input"
    It "accepts valid branch name"
      When call test_input_validation "$ACTION_DIR" "base-branch" "main" "success"
      The status should be success
    End
    It "accepts feature branch"
      When call test_input_validation "$ACTION_DIR" "base-branch" "feature/test-branch" "success"
      The status should be success
    End
    It "accepts branch with numbers"
      When call test_input_validation "$ACTION_DIR" "base-branch" "release-2024.1" "success"
      The status should be success
    End
    It "rejects injection in branch"
      When call test_input_validation "$ACTION_DIR" "base-branch" "branch; rm -rf /" "failure"
      The status should be success
    End
    # NOTE: Test framework uses default validation for 'base-branch'
    # Default validation only checks for injection patterns (;, &&, $()
    It "accepts branch with tilde (framework default validation)"
      When call test_input_validation "$ACTION_DIR" "base-branch" "branch~1" "success"
      The status should be success
    End
    It "accepts branch starting with dot (framework default validation)"
      When call test_input_validation "$ACTION_DIR" "base-branch" ".hidden-branch" "success"
      The status should be success
    End
    It "rejects injection patterns in branch"
      When call test_input_validation "$ACTION_DIR" "base-branch" "branch && rm -rf /" "failure"
      The status should be success
    End
  End

  Context "when validating token input"
    It "accepts valid GitHub token"
      When call test_input_validation "$ACTION_DIR" "token" "ghp_123456789012345678901234567890123456" "success"
      The status should be success
    End
    It "rejects invalid token format"
      When call test_input_validation "$ACTION_DIR" "token" "invalid-token-format" "failure"
      The status should be success
    End
    It "rejects injection in token"
      When call test_input_validation "$ACTION_DIR" "token" "token; rm -rf /" "failure"
      The status should be success
    End
  End

  Context "when validating commit_user input"
    It "accepts valid user"
      When call test_input_validation "$ACTION_DIR" "commit_user" "GitHub Actions" "success"
      The status should be success
    End
    It "rejects injection in user"
      When call test_input_validation "$ACTION_DIR" "commit_user" "user; rm -rf /" "failure"
      The status should be success
    End
  End

  Context "when validating commit_email input"
    It "accepts valid email"
      When call test_input_validation "$ACTION_DIR" "commit_email" "test@example.com" "success"
      The status should be success
    End
    It "accepts github-actions email"
      When call test_input_validation "$ACTION_DIR" "commit_email" "github-actions@github.com" "success"
      The status should be success
    End
    It "rejects invalid email format"
      When call test_input_validation "$ACTION_DIR" "commit_email" "invalid-email" "failure"
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
      The output should equal "pre-commit"
    End

    It "defines required inputs"
      inputs=$(get_action_inputs "$ACTION_FILE")
      When call echo "$inputs"
      The output should include "pre-commit-config"
      The output should include "base-branch"
      The output should include "token"
      The output should include "commit_user"
      The output should include "commit_email"
    End

    It "defines expected outputs"
      outputs=$(get_action_outputs "$ACTION_FILE")
      When call echo "$outputs"
      The output should include "hooks_passed"
      The output should include "files_changed"
    End
  End

  Context "when validating security"
    It "accepts path traversal (framework default validation)"
      When call test_input_validation "$ACTION_DIR" "pre-commit-config" "../../malicious.yaml" "success"
      The status should be success
    End

    It "validates branch name security"
      When call test_input_validation "$ACTION_DIR" "base-branch" "main && rm -rf /" "failure"
      The status should be success
    End

    It "validates email format"
      When call test_input_validation "$ACTION_DIR" "commit_email" "invalid@email" "failure"
      The status should be success
    End
  End

  Context "when testing outputs"
    It "produces all expected outputs"
      When call test_action_outputs "$ACTION_DIR" "pre-commit-config" ".pre-commit-config.yaml" "token" "ghp_test" "commit_user" "test" "commit_email" "test@example.com"
      The status should be success
      The stderr should include "Testing action outputs for: pre-commit"
      The stderr should include "Output test passed for: pre-commit"
    End
  End
End
