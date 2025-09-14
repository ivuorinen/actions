#!/usr/bin/env shellspec
# Unit tests for prettier-fix action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "prettier-fix action"
  ACTION_DIR="prettier-fix"
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

    It "accepts GitHub enterprise token"
      When call test_input_validation "$ACTION_DIR" "token" "ghe_abcdefghijklmnopqrstuvwxyz1234567890" "success"
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

    It "accepts single character username"
      When call test_input_validation "$ACTION_DIR" "username" "a" "success"
      The status should be success
    End

    It "accepts maximum length username"
      When call test_input_validation "$ACTION_DIR" "username" "abcdefghijklmnopqrstuvwxyz0123456789abc" "success"
      The status should be success
    End

    It "rejects username too long"
      When call test_input_validation "$ACTION_DIR" "username" "abcdefghijklmnopqrstuvwxyz0123456789abcd" "failure"
      The status should be success
    End

    It "rejects username with command injection"
      When call test_input_validation "$ACTION_DIR" "username" "user; rm -rf /" "failure"
      The status should be success
    End

    It "rejects username with shell operators"
      When call test_input_validation "$ACTION_DIR" "username" "user && rm -rf /" "failure"
      The status should be success
    End

    It "rejects username with pipe"
      When call test_input_validation "$ACTION_DIR" "username" "user | rm -rf /" "failure"
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

    It "accepts email with plus sign"
      When call test_input_validation "$ACTION_DIR" "email" "user+tag@example.com" "success"
      The status should be success
    End

    It "accepts email with numbers"
      When call test_input_validation "$ACTION_DIR" "email" "user123@example123.com" "success"
      The status should be success
    End

    It "accepts email with hyphens"
      When call test_input_validation "$ACTION_DIR" "email" "user-name@example-domain.com" "success"
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

    It "rejects email without username"
      When call test_input_validation "$ACTION_DIR" "email" "@example.com" "failure"
      The status should be success
    End

    It "rejects email without dot in domain"
      When call test_input_validation "$ACTION_DIR" "email" "user@example" "failure"
      The status should be success
    End

    It "rejects email with spaces"
      When call test_input_validation "$ACTION_DIR" "email" "user @example.com" "failure"
      The status should be success
    End

    It "rejects empty email"
      When call test_input_validation "$ACTION_DIR" "email" "" "failure"
      The status should be success
    End
  End

  Context "when validating max-retries input"
    It "accepts valid retry count"
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

    It "rejects too many retries"
      When call test_input_validation "$ACTION_DIR" "max-retries" "11" "failure"
      The status should be success
    End

    It "rejects non-numeric retries"
      When call test_input_validation "$ACTION_DIR" "max-retries" "many" "failure"
      The status should be success
    End

    It "rejects negative retries"
      When call test_input_validation "$ACTION_DIR" "max-retries" "-1" "failure"
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
      The output should equal "Prettier Fix"
    End

    It "defines expected inputs"
      When call get_action_inputs "$ACTION_FILE"
      The output should include "token"
      The output should include "username"
      The output should include "email"
      The output should include "max-retries"
    End

    It "defines expected outputs"
      When call get_action_outputs "$ACTION_FILE"
      The output should include "files_changed"
      The output should include "format_status"
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

    It "has correct default token"
      When call python3 -c "
      import yaml
      with open('$ACTION_FILE') as f:
      data = yaml.safe_load(f)
      token = data.get('inputs', {}).get('token', {}).get('default', '')
      print(token)
      "
      The output should equal "\${{ github.token }}"
    End

    It "has correct default username"
      When call python3 -c "
      import yaml
      with open('$ACTION_FILE') as f:
      data = yaml.safe_load(f)
      username = data.get('inputs', {}).get('username', {}).get('default', '')
      print(username)
      "
      The output should equal "github-actions"
    End

    It "has correct default email"
      When call python3 -c "
      import yaml
      with open('$ACTION_FILE') as f:
      data = yaml.safe_load(f)
      email = data.get('inputs', {}).get('email', {}).get('default', '')
      print(email)
      "
      The output should equal "github-actions@github.com"
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

    It "validates against backtick injection in email"
      When call test_input_validation "$ACTION_DIR" "email" "user@example.com\`echo test\`" "failure"
      The status should be success
    End
  End

  Context "when testing Prettier-specific validations"
    It "validates username length boundaries for Git"
      When call test_input_validation "$ACTION_DIR" "username" "$(printf 'a%.0s' {1..40})" "failure"
      The status should be success
    End

    It "validates email format for Git commits"
      When call test_input_validation "$ACTION_DIR" "email" "noreply@github.com" "success"
      The status should be success
    End

    It "validates retry count boundaries"
      When call test_input_validation "$ACTION_DIR" "max-retries" "0" "failure"
      The status should be success
    End

    It "validates default values are secure"
      When call test_input_validation "$ACTION_DIR" "username" "github-actions" "success"
      The status should be success
    End
  End
End
