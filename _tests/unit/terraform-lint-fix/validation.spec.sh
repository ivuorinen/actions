#!/usr/bin/env shellspec
# Unit tests for terraform-lint-fix action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "terraform-lint-fix action"
  ACTION_DIR="terraform-lint-fix"
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

  Context "when validating terraform-version input"
    It "accepts valid terraform version"
      When call test_input_validation "$ACTION_DIR" "terraform-version" "1.5.0" "success"
      The status should be success
    End

    It "accepts latest terraform version"
      When call test_input_validation "$ACTION_DIR" "terraform-version" "latest" "success"
      The status should be success
    End

    It "accepts terraform version with patch"
      When call test_input_validation "$ACTION_DIR" "terraform-version" "1.5.7" "success"
      The status should be success
    End

    It "rejects invalid terraform version format"
      When call test_input_validation "$ACTION_DIR" "terraform-version" "v1.5.0" "failure"
      The status should be success
    End

    It "rejects terraform version with command injection"
      When call test_input_validation "$ACTION_DIR" "terraform-version" "1.5.0; rm -rf /" "failure"
      The status should be success
    End

    It "accepts empty terraform version (uses default)"
      When call test_input_validation "$ACTION_DIR" "terraform-version" "" "success"
      The status should be success
    End
  End

  Context "when validating working-directory input"
    It "accepts current directory"
      When call test_input_validation "$ACTION_DIR" "working-directory" "." "success"
      The status should be success
    End

    It "accepts relative directory"
      When call test_input_validation "$ACTION_DIR" "working-directory" "terraform" "success"
      The status should be success
    End

    It "accepts nested directory"
      When call test_input_validation "$ACTION_DIR" "working-directory" "infrastructure/terraform" "success"
      The status should be success
    End

    It "rejects path traversal"
      When call test_input_validation "$ACTION_DIR" "working-directory" "../malicious" "failure"
      The status should be success
    End

    It "rejects absolute paths"
      When call test_input_validation "$ACTION_DIR" "working-directory" "/etc/passwd" "failure"
      The status should be success
    End

    It "rejects directory with command injection"
      When call test_input_validation "$ACTION_DIR" "working-directory" "terraform; rm -rf /" "failure"
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
      The output should equal "Terraform Lint Fix"
    End

    It "defines expected inputs"
      When call get_action_inputs "$ACTION_FILE"
      The output should include "token"
      The output should include "terraform-version"
      The output should include "working-directory"
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
    It "validates against path traversal in working directory"
      When call test_input_validation "$ACTION_DIR" "working-directory" "../../malicious" "failure"
      The status should be success
    End

    It "validates against command injection in terraform version"
      When call test_input_validation "$ACTION_DIR" "terraform-version" "1.5.0\`whoami\`" "failure"
      The status should be success
    End

    It "validates against shell metacharacters in token"
      When call test_input_validation "$ACTION_DIR" "token" "ghp_token && rm -rf /" "failure"
      The status should be success
    End
  End

  Context "when testing Terraform-specific validations"
    It "validates terraform version format"
      When call test_input_validation "$ACTION_DIR" "terraform-version" "1.x.x" "failure"
      The status should be success
    End

    It "validates working directory path safety"
      When call test_input_validation "$ACTION_DIR" "working-directory" "/root/.ssh" "failure"
      The status should be success
    End
  End
End
