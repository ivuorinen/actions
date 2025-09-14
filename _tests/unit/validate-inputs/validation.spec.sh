#!/usr/bin/env shellspec
# Unit tests for validate-inputs action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "validate-inputs action"
  ACTION_DIR="validate-inputs"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating action input"
    It "accepts valid action name"
      When call test_input_validation "$ACTION_DIR" "action" "github-release" "success"
      The status should be success
    End

    It "accepts action name with hyphens"
      When call test_input_validation "$ACTION_DIR" "action" "docker-build" "success"
      The status should be success
    End

    It "accepts action name with underscores"
      When call test_input_validation "$ACTION_DIR" "action" "npm_publish" "success"
      The status should be success
    End

    It "rejects action with command injection"
      When call test_input_validation "$ACTION_DIR" "action" "github-release; rm -rf /" "failure"
      The status should be success
    End

    It "rejects action with shell operators"
      When call test_input_validation "$ACTION_DIR" "action" "github-release && malicious" "failure"
      The status should be success
    End

    It "rejects action with pipe"
      When call test_input_validation "$ACTION_DIR" "action" "github-release | cat /etc/passwd" "failure"
      The status should be success
    End

    It "rejects empty action"
      When call test_input_validation "$ACTION_DIR" "action" "" "failure"
      The status should be success
    End
  End

  Context "when validating rules-file input"
    It "accepts valid rules file"
      When call test_input_validation "$ACTION_DIR" "rules-file" "validate-inputs/rules/github-release.yml" "success"
      The status should be success
    End

    It "accepts rules file with relative path"
      When call test_input_validation "$ACTION_DIR" "rules-file" "rules/action.yml" "success"
      The status should be success
    End

    It "rejects path traversal in rules file"
      When call test_input_validation "$ACTION_DIR" "rules-file" "../../../etc/passwd" "failure"
      The status should be success
    End

    It "rejects absolute path in rules file"
      When call test_input_validation "$ACTION_DIR" "rules-file" "/etc/passwd" "failure"
      The status should be success
    End

    It "rejects rules file with command injection"
      When call test_input_validation "$ACTION_DIR" "rules-file" "rules.yml; rm -rf /" "failure"
      The status should be success
    End

    It "accepts empty rules file (uses default)"
      When call test_input_validation "$ACTION_DIR" "rules-file" "" "success"
      The status should be success
    End
  End

  Context "when validating fail-on-error input"
    It "accepts true for fail-on-error"
      When call test_input_validation "$ACTION_DIR" "fail-on-error" "true" "success"
      The status should be success
    End

    It "accepts false for fail-on-error"
      When call test_input_validation "$ACTION_DIR" "fail-on-error" "false" "success"
      The status should be success
    End

    It "rejects invalid fail-on-error value"
      When call test_input_validation "$ACTION_DIR" "fail-on-error" "yes" "failure"
      The status should be success
    End

    It "rejects empty fail-on-error"
      When call test_input_validation "$ACTION_DIR" "fail-on-error" "" "failure"
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
      The output should equal "Validate Inputs"
    End

    It "defines expected inputs"
      When call get_action_inputs "$ACTION_FILE"
      The output should include "action"
      The output should include "rules-file"
      The output should include "fail-on-error"
    End

    It "defines expected outputs"
      When call get_action_outputs "$ACTION_FILE"
      The output should include "validation-result"
      The output should include "errors-found"
      The output should include "rules-applied"
    End
  End

  Context "when testing input requirements"
    It "requires action input"
      When call python3 -c "
      import yaml
      with open('$ACTION_FILE') as f:
      data = yaml.safe_load(f)
      action = data.get('inputs', {}).get('action', {})
      print('required' if action.get('required', False) else 'optional')
      "
      The output should equal "required"
    End

    It "has rules-file as optional input"
      When call python3 -c "
      import yaml
      with open('$ACTION_FILE') as f:
      data = yaml.safe_load(f)
      rules_file = data.get('inputs', {}).get('rules-file', {})
      print('optional' if 'default' in rules_file else 'required')
      "
      The output should equal "optional"
    End

    It "has fail-on-error as optional input"
      When call python3 -c "
      import yaml
      with open('$ACTION_FILE') as f:
      data = yaml.safe_load(f)
      fail_on_error = data.get('inputs', {}).get('fail-on-error', {})
      print('optional' if 'default' in fail_on_error else 'required')
      "
      The output should equal "optional"
    End
  End

  Context "when testing security validations"
    It "validates against path traversal in rules file"
      When call test_input_validation "$ACTION_DIR" "rules-file" "../../malicious.yml" "failure"
      The status should be success
    End

    It "validates against command injection in action name"
      When call test_input_validation "$ACTION_DIR" "action" "test\`whoami\`" "failure"
      The status should be success
    End

    It "validates against shell metacharacters in rules file"
      When call test_input_validation "$ACTION_DIR" "rules-file" "rules.yml && rm -rf /" "failure"
      The status should be success
    End
  End

  Context "when testing validation-specific functionality"
    It "validates action name format restrictions"
      When call test_input_validation "$ACTION_DIR" "action" "invalid/action/name" "failure"
      The status should be success
    End

    It "validates rules file extension requirements"
      When call test_input_validation "$ACTION_DIR" "rules-file" "rules.txt" "success"
      The status should be success
    End

    It "validates boolean input parsing"
      When call test_input_validation "$ACTION_DIR" "fail-on-error" "TRUE" "failure"
      The status should be success
    End
  End
End
