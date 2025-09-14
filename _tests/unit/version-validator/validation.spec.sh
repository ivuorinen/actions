#!/usr/bin/env shellspec
# Unit tests for version-validator action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "version-validator action"
  ACTION_DIR="version-validator"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating version input"
    It "accepts valid semantic version"
      When call test_input_validation "$ACTION_DIR" "version" "1.2.3" "success"
      The status should be success
    End

    It "accepts semantic version with v prefix"
      When call test_input_validation "$ACTION_DIR" "version" "v1.2.3" "success"
      The status should be success
    End

    It "accepts prerelease version"
      When call test_input_validation "$ACTION_DIR" "version" "1.2.3-alpha" "success"
      The status should be success
    End

    It "accepts prerelease with number"
      When call test_input_validation "$ACTION_DIR" "version" "1.2.3-alpha.1" "success"
      The status should be success
    End

    It "accepts build metadata"
      When call test_input_validation "$ACTION_DIR" "version" "1.2.3+build.1" "success"
      The status should be success
    End

    It "accepts prerelease with build metadata"
      When call test_input_validation "$ACTION_DIR" "version" "1.2.3-alpha.1+build.1" "success"
      The status should be success
    End

    It "accepts CalVer format"
      When call test_input_validation "$ACTION_DIR" "version" "2024.3.1" "success"
      The status should be success
    End

    It "rejects invalid version format"
      When call test_input_validation "$ACTION_DIR" "version" "invalid-version" "failure"
      The status should be success
    End

    It "rejects version with command injection"
      When call test_input_validation "$ACTION_DIR" "version" "1.2.3; rm -rf /" "failure"
      The status should be success
    End

    It "rejects version with shell expansion"
      When call test_input_validation "$ACTION_DIR" "version" "1.2.3\$(whoami)" "failure"
      The status should be success
    End

    It "rejects empty version"
      When call test_input_validation "$ACTION_DIR" "version" "" "failure"
      The status should be success
    End
  End

  Context "when validating validation-type input"
    It "accepts semantic validation type"
      When call test_input_validation "$ACTION_DIR" "validation-type" "semantic" "success"
      The status should be success
    End

    It "accepts calver validation type"
      When call test_input_validation "$ACTION_DIR" "validation-type" "calver" "success"
      The status should be success
    End

    It "accepts flexible validation type"
      When call test_input_validation "$ACTION_DIR" "validation-type" "flexible" "success"
      The status should be success
    End

    It "accepts strict validation type"
      When call test_input_validation "$ACTION_DIR" "validation-type" "strict" "success"
      The status should be success
    End

    It "rejects invalid validation type"
      When call test_input_validation "$ACTION_DIR" "validation-type" "invalid" "failure"
      The status should be success
    End

    It "rejects validation type with command injection"
      When call test_input_validation "$ACTION_DIR" "validation-type" "semantic; rm -rf /" "failure"
      The status should be success
    End

    It "accepts empty validation type (uses default)"
      When call test_input_validation "$ACTION_DIR" "validation-type" "" "success"
      The status should be success
    End
  End

  Context "when validating fail-on-invalid input"
    It "accepts true for fail-on-invalid"
      When call test_input_validation "$ACTION_DIR" "fail-on-invalid" "true" "success"
      The status should be success
    End

    It "accepts false for fail-on-invalid"
      When call test_input_validation "$ACTION_DIR" "fail-on-invalid" "false" "success"
      The status should be success
    End

    It "rejects invalid fail-on-invalid value"
      When call test_input_validation "$ACTION_DIR" "fail-on-invalid" "yes" "failure"
      The status should be success
    End

    It "accepts empty fail-on-invalid (uses default)"
      When call test_input_validation "$ACTION_DIR" "fail-on-invalid" "" "success"
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
      The output should equal "Version Validator"
    End

    It "defines expected inputs"
      When call get_action_inputs "$ACTION_FILE"
      The output should include "version"
      The output should include "validation-type"
      The output should include "fail-on-invalid"
    End

    It "defines expected outputs"
      When call get_action_outputs "$ACTION_FILE"
      The output should include "is-valid"
      The output should include "validation-result"
      The output should include "normalized-version"
    End
  End

  Context "when testing input requirements"
    It "requires version input"
      When call python3 -c "
      import yaml
      with open('$ACTION_FILE') as f:
      data = yaml.safe_load(f)
      version = data.get('inputs', {}).get('version', {})
      print('required' if version.get('required', False) else 'optional')
      "
      The output should equal "required"
    End

    It "has validation-type as optional input"
      When call python3 -c "
      import yaml
      with open('$ACTION_FILE') as f:
      data = yaml.safe_load(f)
      validation_type = data.get('inputs', {}).get('validation-type', {})
      print('optional' if 'default' in validation_type else 'required')
      "
      The output should equal "optional"
    End

    It "has fail-on-invalid as optional input"
      When call python3 -c "
      import yaml
      with open('$ACTION_FILE') as f:
      data = yaml.safe_load(f)
      fail_on_invalid = data.get('inputs', {}).get('fail-on-invalid', {})
      print('optional' if 'default' in fail_on_invalid else 'required')
      "
      The output should equal "optional"
    End
  End

  Context "when testing security validations"
    It "validates against path traversal in version"
      When call test_input_validation "$ACTION_DIR" "version" "../1.2.3" "failure"
      The status should be success
    End

    It "validates against shell metacharacters in version"
      When call test_input_validation "$ACTION_DIR" "version" "1.2.3|echo" "failure"
      The status should be success
    End

    It "validates against backtick injection in validation type"
      When call test_input_validation "$ACTION_DIR" "validation-type" "semantic\`whoami\`" "failure"
      The status should be success
    End

    It "validates against variable expansion in version"
      When call test_input_validation "$ACTION_DIR" "version" "1.2.3\${HOME}" "failure"
      The status should be success
    End
  End

  Context "when testing version validation functionality"
    It "validates semantic version format restrictions"
      When call test_input_validation "$ACTION_DIR" "version" "1.2" "failure"
      The status should be success
    End

    It "validates validation type enum restrictions"
      When call test_input_validation "$ACTION_DIR" "validation-type" "custom" "failure"
      The status should be success
    End

    It "validates boolean input format"
      When call test_input_validation "$ACTION_DIR" "fail-on-invalid" "TRUE" "failure"
      The status should be success
    End

    It "validates complex version formats"
      When call test_input_validation "$ACTION_DIR" "version" "1.2.3-rc.1+build.2024.01.01" "success"
      The status should be success
    End
  End
End
