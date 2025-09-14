#!/usr/bin/env shellspec
# Unit tests for go-build action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "go-build action"
  ACTION_DIR="go-build"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating go-version input"
    It "accepts valid Go version"
      When call test_input_validation "$ACTION_DIR" "go-version" "1.21.0" "success"
      The status should be success
    End

    It "accepts Go version with v prefix"
      When call test_input_validation "$ACTION_DIR" "go-version" "v1.21.0" "success"
      The status should be success
    End

    It "accepts newer Go version"
      When call test_input_validation "$ACTION_DIR" "go-version" "1.22.1" "success"
      The status should be success
    End

    It "accepts prerelease Go version"
      When call test_input_validation "$ACTION_DIR" "go-version" "1.21.0-rc1" "success"
      The status should be success
    End

    It "rejects invalid Go version format"
      When call test_input_validation "$ACTION_DIR" "go-version" "invalid-version" "failure"
      The status should be success
    End

    It "rejects Go version with command injection"
      When call test_input_validation "$ACTION_DIR" "go-version" "1.21; rm -rf /" "failure"
      The status should be success
    End
  End

  Context "when validating destination input"
    It "accepts valid relative path"
      When call test_input_validation "$ACTION_DIR" "destination" "./bin" "success"
      The status should be success
    End

    It "accepts nested directory path"
      When call test_input_validation "$ACTION_DIR" "destination" "build/output" "success"
      The status should be success
    End

    It "accepts simple directory name"
      When call test_input_validation "$ACTION_DIR" "destination" "dist" "success"
      The status should be success
    End

    It "rejects path traversal in destination"
      When call test_input_validation "$ACTION_DIR" "destination" "../bin" "failure"
      The status should be success
    End

    It "rejects absolute path"
      When call test_input_validation "$ACTION_DIR" "destination" "/usr/bin" "failure"
      The status should be success
    End

    It "rejects destination with command injection"
      When call test_input_validation "$ACTION_DIR" "destination" "./bin; rm -rf /" "failure"
      The status should be success
    End
  End

  Context "when validating max-retries input"
    It "accepts valid retry count"
      When call test_input_validation "$ACTION_DIR" "max-retries" "3" "success"
      The status should be success
    End

    It "accepts minimum retry count"
      When call test_input_validation "$ACTION_DIR" "max-retries" "1" "success"
      The status should be success
    End

    It "accepts maximum retry count"
      When call test_input_validation "$ACTION_DIR" "max-retries" "10" "success"
      The status should be success
    End

    It "rejects retry count below minimum"
      When call test_input_validation "$ACTION_DIR" "max-retries" "0" "failure"
      The status should be success
    End

    It "rejects retry count above maximum"
      When call test_input_validation "$ACTION_DIR" "max-retries" "15" "failure"
      The status should be success
    End

    It "rejects non-numeric retry count"
      When call test_input_validation "$ACTION_DIR" "max-retries" "many" "failure"
      The status should be success
    End

    It "rejects decimal retry count"
      When call test_input_validation "$ACTION_DIR" "max-retries" "3.5" "failure"
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
      The output should equal "Go Build"
    End

    It "defines expected inputs"
      When call get_action_inputs "$ACTION_FILE"
      The output should include "go-version"
      The output should include "destination"
      The output should include "max-retries"
    End

    It "defines expected outputs"
      When call get_action_outputs "$ACTION_FILE"
      The output should include "build_status"
      The output should include "test_status"
      The output should include "go_version"
      The output should include "binary_path"
      The output should include "coverage_path"
    End
  End

  Context "when testing input defaults"
    It "has default destination"
      When call python3 -c "
      import yaml
      with open('$ACTION_FILE') as f:
      data = yaml.safe_load(f)
      destination = data.get('inputs', {}).get('destination', {})
      print(destination.get('default', 'no-default'))
      "
      The output should equal "./bin"
    End

    It "has default max-retries"
      When call python3 -c "
      import yaml
      with open('$ACTION_FILE') as f:
      data = yaml.safe_load(f)
      retries = data.get('inputs', {}).get('max-retries', {})
      print(retries.get('default', 'no-default'))
      "
      The output should equal "3"
    End

    It "has all inputs as optional"
      When call python3 -c "
      import yaml
      with open('$ACTION_FILE') as f:
      data = yaml.safe_load(f)
      inputs = data.get('inputs', {})
      required_count = sum(1 for inp in inputs.values() if inp.get('required', False))
      print('all-optional' if required_count == 0 else f'has-{required_count}-required')
      "
      The output should equal "all-optional"
    End
  End

  Context "when testing security validations"
    It "validates against shell injection in go-version"
      When call test_input_validation "$ACTION_DIR" "go-version" "1.21.0|echo test" "failure"
      The status should be success
    End

    It "validates against shell injection in destination"
      When call test_input_validation "$ACTION_DIR" "destination" "bin\$(whoami)" "failure"
      The status should be success
    End

    It "validates against shell injection in max-retries"
      When call test_input_validation "$ACTION_DIR" "max-retries" "3;echo test" "failure"
      The status should be success
    End
  End
End
