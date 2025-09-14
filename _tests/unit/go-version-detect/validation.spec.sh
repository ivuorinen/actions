#!/usr/bin/env shellspec
# Unit tests for go-version-detect action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "go-version-detect action"
  ACTION_DIR="go-version-detect"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating default-version input"
    It "accepts valid semantic version"
      When call test_input_validation "$ACTION_DIR" "default-version" "1.22" "success"
      The status should be success
    End

    It "accepts semantic version with patch"
      When call test_input_validation "$ACTION_DIR" "default-version" "1.21.5" "success"
      The status should be success
    End

    It "accepts minimum supported Go version"
      When call test_input_validation "$ACTION_DIR" "default-version" "1.18" "success"
      The status should be success
    End

    It "accepts current stable Go version"
      When call test_input_validation "$ACTION_DIR" "default-version" "1.22.1" "success"
      The status should be success
    End

    It "rejects version without minor"
      When call test_input_validation "$ACTION_DIR" "default-version" "1" "failure"
      The status should be success
    End

    It "rejects invalid version format"
      When call test_input_validation "$ACTION_DIR" "default-version" "invalid-version" "failure"
      The status should be success
    End

    It "rejects version with command injection"
      When call test_input_validation "$ACTION_DIR" "default-version" "1.22; rm -rf /" "failure"
      The status should be success
    End

    It "rejects version with shell expansion"
      When call test_input_validation "$ACTION_DIR" "default-version" "1.22\$(echo test)" "failure"
      The status should be success
    End

    It "rejects major version other than 1"
      When call test_input_validation "$ACTION_DIR" "default-version" "2.0" "failure"
      The status should be success
    End

    It "rejects too old minor version"
      When call test_input_validation "$ACTION_DIR" "default-version" "1.15" "failure"
      The status should be success
    End

    It "rejects too new minor version"
      When call test_input_validation "$ACTION_DIR" "default-version" "1.50" "failure"
      The status should be success
    End

    It "rejects empty version"
      When call test_input_validation "$ACTION_DIR" "default-version" "" "failure"
      The status should be success
    End

    It "rejects version with leading v"
      When call test_input_validation "$ACTION_DIR" "default-version" "v1.22" "failure"
      The status should be success
    End

    It "rejects version with prerelease"
      When call test_input_validation "$ACTION_DIR" "default-version" "1.22-beta" "failure"
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
      The output should equal "Go Version Detect"
    End

    It "defines expected inputs"
      When call get_action_inputs "$ACTION_FILE"
      The output should include "default-version"
    End

    It "defines expected outputs"
      When call get_action_outputs "$ACTION_FILE"
      The output should include "go-version"
    End
  End

  Context "when testing input requirements"
    It "has default-version as optional input"
      # Test that default-version has a default value in action.yml
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
      The output should equal "1.22"
    End
  End

  Context "when testing security validations"
    It "validates against path traversal in version"
      When call test_input_validation "$ACTION_DIR" "default-version" "../1.22" "failure"
      The status should be success
    End

    It "validates against shell metacharacters in version"
      When call test_input_validation "$ACTION_DIR" "default-version" "1.22|echo" "failure"
      The status should be success
    End

    It "validates against backtick injection"
      When call test_input_validation "$ACTION_DIR" "default-version" "1.22\`whoami\`" "failure"
      The status should be success
    End

    It "validates against variable expansion"
      When call test_input_validation "$ACTION_DIR" "default-version" "1.22\${HOME}" "failure"
      The status should be success
    End
  End

  Context "when testing version range validation"
    It "validates reasonable Go version range boundaries"
      # Test boundary conditions for Go version validation
      When call test_input_validation "$ACTION_DIR" "default-version" "1.16" "failure"
      The status should be success
    End

    It "validates upper boundary"
      When call test_input_validation "$ACTION_DIR" "default-version" "1.31" "failure"
      The status should be success
    End

    It "validates exact boundary valid values"
      When call test_input_validation "$ACTION_DIR" "default-version" "1.18" "success"
      The status should be success
    End

    It "validates exact boundary valid values upper"
      When call test_input_validation "$ACTION_DIR" "default-version" "1.30" "success"
      The status should be success
    End
  End
End
