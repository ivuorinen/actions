#!/usr/bin/env shellspec
# Unit tests for csharp-publish action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "csharp-publish action"
  ACTION_DIR="csharp-publish"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating inputs"
    It "accepts valid dotnet version"
      When call test_input_validation "$ACTION_DIR" "dotnet-version" "8.0" "success"
      The status should be success
    End
    It "accepts valid namespace"
      When call test_input_validation "$ACTION_DIR" "namespace" "ivuorinen" "success"
      The status should be success
    End
    It "accepts namespace with hyphens in middle"
      When call test_input_validation "$ACTION_DIR" "namespace" "my-org-name" "success"
      The status should be success
    End
    It "rejects namespace ending with hyphen"
      When call test_input_validation "$ACTION_DIR" "namespace" "invalid-" "failure"
      The status should be success
    End
    It "accepts valid GitHub token"
      When call test_input_validation "$ACTION_DIR" "token" "ghp_123456789012345678901234567890123456" "success"
      The status should be success
    End
    It "rejects injection in namespace"
      When call test_input_validation "$ACTION_DIR" "namespace" "invalid;malicious" "failure"
      The status should be success
    End
    It "rejects injection in token"
      When call test_input_validation "$ACTION_DIR" "token" "token;rm -rf /" "failure"
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
