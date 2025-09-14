#!/usr/bin/env shellspec
# Unit tests for python-version-detect action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "python-version-detect action"
  ACTION_DIR="python-version-detect"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating default-version input"
    It "accepts valid Python version"
      When call test_input_validation "$ACTION_DIR" "default-version" "3.11" "success"
      The status should be success
    End

    It "accepts Python version with patch"
      When call test_input_validation "$ACTION_DIR" "default-version" "3.11.5" "success"
      The status should be success
    End

    It "accepts Python 3.8"
      When call test_input_validation "$ACTION_DIR" "default-version" "3.8" "success"
      The status should be success
    End

    It "accepts Python 3.12"
      When call test_input_validation "$ACTION_DIR" "default-version" "3.12" "success"
      The status should be success
    End

    It "rejects Python version too old"
      When call test_input_validation "$ACTION_DIR" "default-version" "2.7" "failure"
      The status should be success
    End

    It "rejects Python version too new"
      When call test_input_validation "$ACTION_DIR" "default-version" "4.0" "failure"
      The status should be success
    End

    It "rejects invalid version format"
      When call test_input_validation "$ACTION_DIR" "default-version" "python3.11" "failure"
      The status should be success
    End

    It "rejects version with command injection"
      When call test_input_validation "$ACTION_DIR" "default-version" "3.11; rm -rf /" "failure"
      The status should be success
    End

    It "rejects version without minor"
      When call test_input_validation "$ACTION_DIR" "default-version" "3" "failure"
      The status should be success
    End

    It "rejects empty version"
      When call test_input_validation "$ACTION_DIR" "default-version" "" "failure"
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
      The output should equal "Python Version Detect"
    End

    It "defines expected inputs"
      When call get_action_inputs "$ACTION_FILE"
      The output should include "default-version"
    End

    It "defines expected outputs"
      When call get_action_outputs "$ACTION_FILE"
      The output should include "python-version"
    End
  End

  Context "when testing input requirements"
    It "has default-version as optional input"
      When call python3 -c "
      import yaml
      with open('$ACTION_FILE') as f:
      data = yaml.safe_load(f)
      default_version = data.get('inputs', {}).get('default-version', {})
      print('optional' if 'default' in default_version else 'required')
      "
      The output should equal "optional"
    End
  End

  Context "when testing security validations"
    It "validates against path traversal in version"
      When call test_input_validation "$ACTION_DIR" "default-version" "../3.11" "failure"
      The status should be success
    End

    It "validates against shell metacharacters in version"
      When call test_input_validation "$ACTION_DIR" "default-version" "3.11|echo" "failure"
      The status should be success
    End

    It "validates against backtick injection"
      When call test_input_validation "$ACTION_DIR" "default-version" "3.11\`whoami\`" "failure"
      The status should be success
    End
  End
End
