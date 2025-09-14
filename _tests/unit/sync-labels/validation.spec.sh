#!/usr/bin/env shellspec
# Unit tests for sync-labels action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "sync-labels action"
  ACTION_DIR="sync-labels"
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
  End

  Context "when validating config-file input"
    It "accepts valid config file"
      When call test_input_validation "$ACTION_DIR" "config-file" ".github/labels.yml" "success"
      The status should be success
    End

    It "accepts config file with json extension"
      When call test_input_validation "$ACTION_DIR" "config-file" ".github/labels.json" "success"
      The status should be success
    End

    It "rejects path traversal in config file"
      When call test_input_validation "$ACTION_DIR" "config-file" "../../../etc/passwd" "failure"
      The status should be success
    End

    It "rejects absolute path in config file"
      When call test_input_validation "$ACTION_DIR" "config-file" "/etc/passwd" "failure"
      The status should be success
    End

    It "rejects config file with command injection"
      When call test_input_validation "$ACTION_DIR" "config-file" "labels.yml; rm -rf /" "failure"
      The status should be success
    End
  End

  Context "when validating dry-run input"
    It "accepts true for dry-run"
      When call test_input_validation "$ACTION_DIR" "dry-run" "true" "success"
      The status should be success
    End

    It "accepts false for dry-run"
      When call test_input_validation "$ACTION_DIR" "dry-run" "false" "success"
      The status should be success
    End

    It "rejects invalid dry-run value"
      When call test_input_validation "$ACTION_DIR" "dry-run" "yes" "failure"
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
      The output should equal "Sync Labels"
    End

    It "defines expected inputs"
      When call get_action_inputs "$ACTION_FILE"
      The output should include "token"
      The output should include "config-file"
      The output should include "dry-run"
    End
  End

  Context "when testing input requirements"
    It "requires token input"
      When call python3 -c "
      import yaml
      with open('$ACTION_FILE') as f:
      data = yaml.safe_load(f)
      token = data.get('inputs', {}).get('token', {})
      print('required' if token.get('required', False) else 'optional')
      "
      The output should equal "required"
    End
  End

  Context "when testing security validations"
    It "validates against path traversal in config file"
      When call test_input_validation "$ACTION_DIR" "config-file" "../../malicious.yml" "failure"
      The status should be success
    End

    It "validates against command injection in token"
      When call test_input_validation "$ACTION_DIR" "token" "ghp_token\`whoami\`" "failure"
      The status should be success
    End

    It "validates against shell metacharacters in config file"
      When call test_input_validation "$ACTION_DIR" "config-file" "labels.yml && rm -rf /" "failure"
      The status should be success
    End
  End
End
