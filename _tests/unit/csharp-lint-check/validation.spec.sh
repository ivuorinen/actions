#!/usr/bin/env shellspec
# Unit tests for csharp-lint-check action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "csharp-lint-check action"
  ACTION_DIR="csharp-lint-check"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating inputs"
    It "accepts valid dotnet version"
      When call test_input_validation "$ACTION_DIR" "dotnet-version" "8.0" "success"
      The status should be success
    End
    It "accepts valid working directory"
      When call test_input_validation "$ACTION_DIR" "working-directory" "src" "success"
      The status should be success
    End
    It "rejects path traversal"
      When call test_input_validation "$ACTION_DIR" "working-directory" "../../../etc" "failure"
      The status should be success
    End
    It "rejects injection"
      When call test_input_validation "$ACTION_DIR" "dotnet-version" "8.0;malicious" "failure"
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
  End
End
