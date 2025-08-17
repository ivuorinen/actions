#!/usr/bin/env shellspec
# Unit tests for csharp-build action validation and logic
# Framework is automatically loaded via spec_helper.sh

Describe "csharp-build action"
  ACTION_DIR="csharp-build"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating dotnet-version input"
    It "accepts valid dotnet version"
      When call test_input_validation "$ACTION_DIR" "dotnet-version" "8.0" "success"
      The status should be success
    End
    It "accepts dotnet 6 LTS"
      When call test_input_validation "$ACTION_DIR" "dotnet-version" "6.0" "success"
      The status should be success
    End
    It "rejects invalid version"
      When call test_input_validation "$ACTION_DIR" "dotnet-version" "invalid" "failure"
      The status should be success
    End
  End

  Context "when validating max-retries input"
    It "accepts valid max-retries"
      When call test_input_validation "$ACTION_DIR" "max-retries" "3" "success"
      The status should be success
    End
    It "accepts minimum retries"
      When call test_input_validation "$ACTION_DIR" "max-retries" "1" "success"
      The status should be success
    End
    It "rejects zero retries"
      When call test_input_validation "$ACTION_DIR" "max-retries" "0" "failure"
      The status should be success
    End
    It "rejects non-numeric retries"
      When call test_input_validation "$ACTION_DIR" "max-retries" "invalid" "failure"
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
      The output should match pattern "*C#*"
    End

    It "defines expected inputs"
      inputs=$(get_action_inputs "$ACTION_FILE")
      When call echo "$inputs"
      The output should include "dotnet-version"
      The output should include "max-retries"
    End

    It "defines expected outputs"
      outputs=$(get_action_outputs "$ACTION_FILE")
      When call echo "$outputs"
      The output should include "build_status"
      The output should include "test_status"
      The output should include "dotnet_version"
      The output should include "artifacts_path"
      The output should include "test_results_path"
    End
  End

  Context "when testing outputs"
    It "produces all expected outputs consistently"
      When call test_action_outputs "$ACTION_DIR" "dotnet-version" "8.0" "max-retries" "3"
      The status should be success
      The stderr should include "Testing action outputs for: csharp-build"
      The stderr should include "Output test passed for: csharp-build"
    End
  End
End
