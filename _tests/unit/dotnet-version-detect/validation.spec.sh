#!/usr/bin/env shellspec
# Unit tests for dotnet-version-detect action validation and logic
# Framework is automatically loaded via spec_helper.sh

Describe "dotnet-version-detect action"
  ACTION_DIR="dotnet-version-detect"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating default-version input"
    It "accepts valid dotnet version"
      When call test_input_validation "$ACTION_DIR" "default-version" "8.0" "success"
      The status should be success
    End
    It "accepts full semantic version"
      When call test_input_validation "$ACTION_DIR" "default-version" "8.0.0" "success"
      The status should be success
    End
    It "accepts dotnet 6 version"
      When call test_input_validation "$ACTION_DIR" "default-version" "6.0.0" "success"
      The status should be success
    End
    It "accepts dotnet 7 version"
      When call test_input_validation "$ACTION_DIR" "default-version" "7.0.0" "success"
      The status should be success
    End
    It "rejects invalid version format"
      When call test_input_validation "$ACTION_DIR" "default-version" "invalid" "failure"
      The status should be success
    End
    It "rejects version with leading zeros"
      When call test_input_validation "$ACTION_DIR" "default-version" "08.0.0" "failure"
      The status should be success
    End
    It "rejects unsupported version"
      When call test_input_validation "$ACTION_DIR" "default-version" "2.0.0" "failure"
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
      The output should equal "Dotnet Version Detect"
    End

    It "defines expected inputs"
      inputs=$(get_action_inputs "$ACTION_FILE")
      When call echo "$inputs"
      The output should include "default-version"
    End

    It "defines expected outputs"
      outputs=$(get_action_outputs "$ACTION_FILE")
      When call echo "$outputs"
      The output should include "dotnet-version"
    End
  End

  Context "when validating security"
    It "rejects injection in version"
      When call test_input_validation "$ACTION_DIR" "default-version" "8.0;malicious" "failure"
      The status should be success
    End

    It "validates path security"
      When call test_input_validation "$ACTION_DIR" "default-version" "src&&dangerous" "failure"
      The status should be success
    End
  End

  Context "when testing outputs"
    It "produces all expected outputs consistently"
      When call test_action_outputs "$ACTION_DIR" "default-version" "8.0"
      The status should be success
      The stderr should include "Testing action outputs for: dotnet-version-detect"
      The stderr should include "Output test passed for: dotnet-version-detect"
    End
  End
End
