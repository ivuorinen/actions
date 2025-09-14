#!/usr/bin/env shellspec
# Unit tests for stale action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "stale action"
  ACTION_DIR="stale"
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

  Context "when validating days-before-stale input"
    It "accepts valid day count"
      When call test_input_validation "$ACTION_DIR" "days-before-stale" "30" "success"
      The status should be success
    End

    It "accepts minimum days"
      When call test_input_validation "$ACTION_DIR" "days-before-stale" "1" "success"
      The status should be success
    End

    It "accepts reasonable maximum days"
      When call test_input_validation "$ACTION_DIR" "days-before-stale" "365" "success"
      The status should be success
    End

    It "rejects zero days"
      When call test_input_validation "$ACTION_DIR" "days-before-stale" "0" "failure"
      The status should be success
    End

    It "rejects negative days"
      When call test_input_validation "$ACTION_DIR" "days-before-stale" "-1" "failure"
      The status should be success
    End

    It "rejects non-numeric days"
      When call test_input_validation "$ACTION_DIR" "days-before-stale" "many" "failure"
      The status should be success
    End
  End

  Context "when validating days-before-close input"
    It "accepts valid day count"
      When call test_input_validation "$ACTION_DIR" "days-before-close" "7" "success"
      The status should be success
    End

    It "accepts minimum days"
      When call test_input_validation "$ACTION_DIR" "days-before-close" "1" "success"
      The status should be success
    End

    It "accepts reasonable maximum days"
      When call test_input_validation "$ACTION_DIR" "days-before-close" "365" "success"
      The status should be success
    End

    It "rejects zero days"
      When call test_input_validation "$ACTION_DIR" "days-before-close" "0" "failure"
      The status should be success
    End

    It "rejects negative days"
      When call test_input_validation "$ACTION_DIR" "days-before-close" "-1" "failure"
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
      The output should equal "Close Stale Issues"
    End

    It "defines expected inputs"
      When call get_action_inputs "$ACTION_FILE"
      The output should include "token"
      The output should include "days-before-stale"
      The output should include "days-before-close"
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
    It "validates against command injection in token"
      When call test_input_validation "$ACTION_DIR" "token" "ghp_token\`whoami\`" "failure"
      The status should be success
    End

    It "validates against variable expansion in days"
      When call test_input_validation "$ACTION_DIR" "days-before-stale" "30\${HOME}" "failure"
      The status should be success
    End

    It "validates against shell metacharacters in days"
      When call test_input_validation "$ACTION_DIR" "days-before-close" "7; rm -rf /" "failure"
      The status should be success
    End
  End
End
