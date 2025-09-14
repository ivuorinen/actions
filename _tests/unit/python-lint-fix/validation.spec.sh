#!/usr/bin/env shellspec
# Unit tests for python-lint-fix action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "python-lint-fix action"
  ACTION_DIR="python-lint-fix"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating token input"
    It "accepts GitHub token expression"
      When call test_input_validation "$ACTION_DIR" "token" "\${{ github.token }}" "success"
      The status should be success
    End

    It "accepts GitHub fine-grained token"
      When call test_input_validation "$ACTION_DIR" "token" "ghp_abcdefghijklmnopqrstuvwxyz1234567890" "success"
      The status should be success
    End

    It "accepts GitHub app token"
      When call test_input_validation "$ACTION_DIR" "token" "ghs_abcdefghijklmnopqrstuvwxyz1234567890" "success"
      The status should be success
    End

    It "rejects invalid token format"
      When call test_input_validation "$ACTION_DIR" "token" "invalid-token" "failure"
      The status should be success
    End

    It "rejects token with command injection"
      When call test_input_validation "$ACTION_DIR" "token" "ghp_token; rm -rf /" "failure"
      The status should be success
    End

    It "accepts empty token (uses default)"
      When call test_input_validation "$ACTION_DIR" "token" "" "success"
      The status should be success
    End
  End

  Context "when validating username input"
    It "accepts valid GitHub username"
      When call test_input_validation "$ACTION_DIR" "username" "github-actions" "success"
      The status should be success
    End

    It "accepts username with hyphens"
      When call test_input_validation "$ACTION_DIR" "username" "user-name" "success"
      The status should be success
    End

    It "accepts username with numbers"
      When call test_input_validation "$ACTION_DIR" "username" "user123" "success"
      The status should be success
    End

    It "rejects username too long"
      When call test_input_validation "$ACTION_DIR" "username" "$(printf 'a%.0s' {1..40})" "failure"
      The status should be success
    End

    It "rejects username with command injection"
      When call test_input_validation "$ACTION_DIR" "username" "user; rm -rf /" "failure"
      The status should be success
    End

    It "accepts empty username (uses default)"
      When call test_input_validation "$ACTION_DIR" "username" "" "success"
      The status should be success
    End
  End

  Context "when validating email input"
    It "accepts valid email"
      When call test_input_validation "$ACTION_DIR" "email" "user@example.com" "success"
      The status should be success
    End

    It "accepts email with subdomain"
      When call test_input_validation "$ACTION_DIR" "email" "user@mail.example.com" "success"
      The status should be success
    End

    It "rejects email without at symbol"
      When call test_input_validation "$ACTION_DIR" "email" "userexample.com" "failure"
      The status should be success
    End

    It "rejects email without domain"
      When call test_input_validation "$ACTION_DIR" "email" "user@" "failure"
      The status should be success
    End

    It "rejects email with spaces"
      When call test_input_validation "$ACTION_DIR" "email" "user @example.com" "failure"
      The status should be success
    End

    It "accepts empty email (uses default)"
      When call test_input_validation "$ACTION_DIR" "email" "" "success"
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
      The output should equal "Python Lint Fix"
    End

    It "defines expected inputs"
      When call get_action_inputs "$ACTION_FILE"
      The output should include "token"
      The output should include "username"
      The output should include "email"
    End
  End

  Context "when testing input requirements"
    It "has all inputs as optional"
      When call python3 -c "
      import yaml
      with open('$ACTION_FILE') as f:
      data = yaml.safe_load(f)
      inputs = data.get('inputs', {})
      required_inputs = [k for k, v in inputs.items() if v.get('required', False)]
      print('none' if not required_inputs else ','.join(required_inputs))
      "
      The output should equal "none"
    End
  End

  Context "when testing security validations"
    It "validates against command injection in username"
      When call test_input_validation "$ACTION_DIR" "username" "user\`whoami\`" "failure"
      The status should be success
    End

    It "validates against shell metacharacters in email"
      When call test_input_validation "$ACTION_DIR" "email" "user@example.com; rm -rf /" "failure"
      The status should be success
    End

    It "validates against variable expansion in token"
      When call test_input_validation "$ACTION_DIR" "token" "\${MALICIOUS_VAR}" "failure"
      The status should be success
    End
  End
End
