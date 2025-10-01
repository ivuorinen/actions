#!/usr/bin/env shellspec
# Unit tests for ansible-lint-fix action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "ansible-lint-fix action"
  ACTION_DIR="ansible-lint-fix"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating token input"
    It "accepts all GitHub token formats"
      When call validate_input_python "ansible-lint-fix" "token" "ghp_123456789012345678901234567890123456"
      The status should be success
    End
    It "accepts organization token"
      When call validate_input_python "ansible-lint-fix" "token" "gho_123456789012345678901234567890123456"
      The status should be success
    End
    It "accepts user token"
      When call validate_input_python "ansible-lint-fix" "token" "ghu_123456789012345678901234567890123456"
      The status should be success
    End
    It "accepts server token"
      When call validate_input_python "ansible-lint-fix" "token" "ghs_123456789012345678901234567890123456"
      The status should be success
    End
    It "accepts refresh token"
      When call validate_input_python "ansible-lint-fix" "token" "ghr_123456789012345678901234567890123456"
      The status should be success
    End
  End

  Context "when validating email input"
    It "accepts valid email"
      When call validate_input_python "ansible-lint-fix" "email" "test@example.com"
      The status should be success
    End
    It "rejects invalid email without @"
      When call validate_input_python "ansible-lint-fix" "email" "testexample.com"
      The status should be failure
    End
    It "rejects invalid email without domain"
      When call validate_input_python "ansible-lint-fix" "email" "test@"
      The status should be failure
    End
  End

  Context "when validating username input"
    It "accepts valid username"
      When call validate_input_python "ansible-lint-fix" "username" "github-actions"
      The status should be success
    End
    It "rejects semicolon injection"
      When call validate_input_python "ansible-lint-fix" "username" "user;rm -rf /"
      The status should be failure
    End
    It "rejects ampersand injection"
      When call validate_input_python "ansible-lint-fix" "username" "user&&malicious"
      The status should be failure
    End
    It "rejects pipe injection"
      When call validate_input_python "ansible-lint-fix" "username" "user|dangerous"
      The status should be failure
    End
    It "rejects overly long username"
      When call validate_input_python "ansible-lint-fix" "username" "this-username-is-definitely-too-long-for-github-maximum-length-limit"
      The status should be failure
    End
  End

  Context "when validating max-retries input"
    It "accepts valid retry count"
      When call validate_input_python "ansible-lint-fix" "max-retries" "5"
      The status should be success
    End
    It "rejects zero retries"
      When call validate_input_python "ansible-lint-fix" "max-retries" "0"
      The status should be failure
    End
    It "rejects negative retries"
      When call validate_input_python "ansible-lint-fix" "max-retries" "-1"
      The status should be failure
    End
    It "rejects retries above limit"
      When call validate_input_python "ansible-lint-fix" "max-retries" "15"
      The status should be failure
    End
    It "rejects non-numeric retries"
      When call validate_input_python "ansible-lint-fix" "max-retries" "invalid"
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
      The output should equal "Ansible Lint and Fix"
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
      The output should include "lint_status"
      The output should include "sarif_path"
    End
  End

  Context "when validating security"
    It "rejects command injection in token"
      When call validate_input_python "ansible-lint-fix" "token" "ghp_123;rm -rf /"
      The status should be failure
    End

    It "rejects command injection in email"
      When call validate_input_python "ansible-lint-fix" "email" "user@domain.com;rm -rf /"
      The status should be failure
    End

    It "validates all inputs for injection patterns"
      # Username injection testing already covered above
      When call validate_input_python "ansible-lint-fix" "max-retries" "3;malicious"
      The status should be failure
    End
  End

  Context "when testing outputs"
    It "produces all expected outputs consistently"
      When call test_action_outputs "$ACTION_DIR" "token" "ghp_123456789012345678901234567890123456" "username" "github-actions" "email" "test@example.com" "max-retries" "3"
      The status should be success
      The stderr should include "Testing action outputs for: ansible-lint-fix"
      The stderr should include "Output test passed for: ansible-lint-fix"
    End
  End
End
