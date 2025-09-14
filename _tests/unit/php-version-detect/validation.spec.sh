#!/usr/bin/env shellspec
# Unit tests for php-version-detect action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "php-version-detect action"
  ACTION_DIR="php-version-detect"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating default-version input"
    It "accepts valid PHP version"
      When call test_input_validation "$ACTION_DIR" "default-version" "8.2" "success"
      The status should be success
    End

    It "accepts PHP version with patch"
      When call test_input_validation "$ACTION_DIR" "default-version" "8.3.1" "success"
      The status should be success
    End

    It "accepts PHP 7.4"
      When call test_input_validation "$ACTION_DIR" "default-version" "7.4" "success"
      The status should be success
    End

    It "accepts PHP 8.0"
      When call test_input_validation "$ACTION_DIR" "default-version" "8.0" "success"
      The status should be success
    End

    It "accepts PHP 8.1"
      When call test_input_validation "$ACTION_DIR" "default-version" "8.1" "success"
      The status should be success
    End

    It "accepts PHP 8.4"
      When call test_input_validation "$ACTION_DIR" "default-version" "8.4" "success"
      The status should be success
    End

    It "rejects PHP version too old"
      When call test_input_validation "$ACTION_DIR" "default-version" "5.6" "failure"
      The status should be success
    End

    It "rejects PHP version too new"
      When call test_input_validation "$ACTION_DIR" "default-version" "10.0" "failure"
      The status should be success
    End

    It "rejects invalid version format"
      When call test_input_validation "$ACTION_DIR" "default-version" "php8.2" "failure"
      The status should be success
    End

    It "rejects version with command injection"
      When call test_input_validation "$ACTION_DIR" "default-version" "8.2; rm -rf /" "failure"
      The status should be success
    End

    It "rejects version without minor"
      When call test_input_validation "$ACTION_DIR" "default-version" "8" "failure"
      The status should be success
    End

    It "rejects empty version"
      When call test_input_validation "$ACTION_DIR" "default-version" "" "failure"
      The status should be success
    End

    It "rejects version with v prefix"
      When call test_input_validation "$ACTION_DIR" "default-version" "v8.2" "failure"
      The status should be success
    End

    It "rejects PHP 8 with invalid minor version"
      When call test_input_validation "$ACTION_DIR" "default-version" "8.5" "failure"
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
      The output should equal "PHP Version Detect"
    End

    It "defines expected inputs"
      When call get_action_inputs "$ACTION_FILE"
      The output should include "default-version"
    End

    It "defines expected outputs"
      When call get_action_outputs "$ACTION_FILE"
      The output should include "php-version"
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

    It "has correct default version"
      When call python3 -c "
      import yaml
      with open('$ACTION_FILE') as f:
      data = yaml.safe_load(f)
      default_version = data.get('inputs', {}).get('default-version', {}).get('default', '')
      print(default_version)
      "
      The output should equal "8.2"
    End
  End

  Context "when testing security validations"
    It "validates against path traversal in version"
      When call test_input_validation "$ACTION_DIR" "default-version" "../8.2" "failure"
      The status should be success
    End

    It "validates against shell metacharacters in version"
      When call test_input_validation "$ACTION_DIR" "default-version" "8.2|echo" "failure"
      The status should be success
    End

    It "validates against backtick injection"
      When call test_input_validation "$ACTION_DIR" "default-version" "8.2\`whoami\`" "failure"
      The status should be success
    End

    It "validates against variable expansion"
      When call test_input_validation "$ACTION_DIR" "default-version" "8.2\${HOME}" "failure"
      The status should be success
    End
  End

  Context "when testing PHP version range validation"
    It "validates PHP 7 minor version boundaries"
      When call test_input_validation "$ACTION_DIR" "default-version" "7.0" "success"
      The status should be success
    End

    It "validates PHP 7.4 specifically"
      When call test_input_validation "$ACTION_DIR" "default-version" "7.4" "success"
      The status should be success
    End

    It "validates PHP 8 minor version boundaries"
      When call test_input_validation "$ACTION_DIR" "default-version" "8.0" "success"
      The status should be success
    End

    It "validates PHP 8.4 boundary"
      When call test_input_validation "$ACTION_DIR" "default-version" "8.4" "success"
      The status should be success
    End

    It "validates PHP 9 future version"
      When call test_input_validation "$ACTION_DIR" "default-version" "9.0" "success"
      The status should be success
    End
  End
End
