#!/usr/bin/env shellspec
# Unit tests for csharp-publish action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "csharp-publish action"
  ACTION_DIR="csharp-publish"
  ACTION_FILE="$ACTION_DIR/action.yml"

  Context "when validating inputs"
    It "accepts valid dotnet version"
      When call validate_input_python "csharp-publish" "dotnet-version" "8.0"
      The status should be success
    End
    It "accepts valid namespace"
      When call validate_input_python "csharp-publish" "namespace" "ivuorinen"
      The status should be success
    End
    It "accepts namespace with hyphens in middle"
      When call validate_input_python "csharp-publish" "namespace" "my-org-name"
      The status should be success
    End
    It "rejects namespace ending with hyphen"
      When call validate_input_python "csharp-publish" "namespace" "invalid-"
      The status should be failure
    End
    It "accepts valid GitHub token"
      When call validate_input_python "csharp-publish" "token" "ghp_123456789012345678901234567890123456"
      The status should be success
    End
    It "rejects injection in namespace"
      When call validate_input_python "csharp-publish" "namespace" "invalid;malicious"
      The status should be failure
    End
    It "rejects injection in token"
      When call validate_input_python "csharp-publish" "token" "token;rm -rf /"
      The status should be failure
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
