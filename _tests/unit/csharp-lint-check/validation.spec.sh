#!/usr/bin/env shellspec
# Unit tests for csharp-lint-check action validation and logic

# Framework is automatically loaded via spec_helper.sh

Describe "csharp-lint-check action"
ACTION_DIR="csharp-lint-check"
ACTION_FILE="$ACTION_DIR/action.yml"

Context "when validating inputs"
It "accepts valid dotnet version"
When call validate_input_python "csharp-lint-check" "dotnet-version" "8.0"
The status should be success
End
It "accepts valid dotnet version format"
When call validate_input_python "csharp-lint-check" "dotnet-version" "8.0.100"
The status should be success
End
It "rejects injection"
When call validate_input_python "csharp-lint-check" "dotnet-version" "8.0;malicious"
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
